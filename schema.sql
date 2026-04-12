-- 1. Profiles (User Data)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('cashier', 'owner')),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Categories
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Menu Items
CREATE TABLE IF NOT EXISTS public.menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price BIGINT NOT NULL DEFAULT 0,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    unit TEXT NOT NULL DEFAULT 'pcs',
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.1 Menu Item Variants
CREATE TABLE IF NOT EXISTS public.menu_item_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    option_name TEXT NOT NULL,
    variant_name TEXT NOT NULL,
    price BIGINT NOT NULL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'pcs',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Modifier Groups
CREATE TABLE IF NOT EXISTS public.modifier_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Modifier Options
CREATE TABLE IF NOT EXISTS public.modifier_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modifier_group_id UUID NOT NULL REFERENCES public.modifier_groups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    additional_price BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Menu Item Modifier Mapping (Many-to-Many)
CREATE TABLE IF NOT EXISTS public.menu_modifier_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
    modifier_group_id UUID NOT NULL REFERENCES public.modifier_groups(id) ON DELETE CASCADE,
    UNIQUE(menu_item_id, modifier_group_id)
);

-- 7. Orders
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE NOT NULL,
    table_number INTEGER NOT NULL,
    cashier_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    subtotal BIGINT NOT NULL,
    tax NUMERIC NOT NULL,
    service_charge NUMERIC NOT NULL,
    total BIGINT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Payments
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    method TEXT NOT NULL CHECK (method IN ('QRIS', 'CASH')),
    amount_paid BIGINT NOT NULL,
    amount_due BIGINT NOT NULL,
    change_given BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Order Items
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price BIGINT NOT NULL,
    notes TEXT,
    modifier_snapshot TEXT, -- Stored as a concatenated string or JSON summary
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Store Settings
CREATE TABLE IF NOT EXISTS public.store_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_percentage NUMERIC NOT NULL DEFAULT 0,
    service_charge_percentage NUMERIC NOT NULL DEFAULT 0,
    store_name TEXT NOT NULL DEFAULT 'FlowPOS',
    store_address TEXT NOT NULL DEFAULT 'No Address',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Atomic Order Creation Function (Called via RPC)
CREATE OR REPLACE FUNCTION public.create_order_atomic(
    p_order_number TEXT,
    p_table_number INTEGER,
    p_cashier_id UUID,
    p_subtotal BIGINT,
    p_tax NUMERIC,
    p_service_charge NUMERIC,
    p_total BIGINT,
    p_method TEXT,
    p_amount_paid BIGINT,
    p_amount_due BIGINT,
    p_change_given BIGINT,
    p_items JSONB
) RETURNS JSONB AS $$
DECLARE
    v_order_id UUID;
    v_payment_id UUID;
    v_created_at TIMESTAMPTZ;
    v_item JSONB;
BEGIN
    -- 1. Insert Order
    INSERT INTO public.orders (
        order_number, table_number, cashier_id, subtotal, tax, service_charge, total
    ) VALUES (
        p_order_number, p_table_number, p_cashier_id, p_subtotal, p_tax, p_service_charge, p_total
    ) RETURNING id, created_at INTO v_order_id, v_created_at;

    -- 2. Insert Payment
    INSERT INTO public.payments (
        order_id, method, amount_paid, amount_due, change_given
    ) VALUES (
        v_order_id, p_method, p_amount_paid, p_amount_due, p_change_given
    ) RETURNING id INTO v_payment_id;

    -- 3. Insert Order Items from JSON payload
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.order_items (
            order_id, menu_item_id, quantity, unit_price, notes, modifier_snapshot
        ) VALUES (
            v_order_id,
            (v_item->>'menu_item_id')::UUID,
            (v_item->>'quantity')::INTEGER,
            (v_item->>'unit_price')::BIGINT,
            v_item->>'notes',
            v_item->>'modifier_snapshot'
        );
    END LOOP;

    RETURN jsonb_build_object(
        'order_id', v_order_id,
        'payment_id', v_payment_id,
        'created_at', v_created_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Triggers for Automatic Profile Creation (Auth sync)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name, role)
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'name', 'User'),
        COALESCE(new.raw_user_meta_data->>'role', 'cashier')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 13. Cashier Shifts
CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cashier_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    opened_at TIMESTAMPTZ NOT NULL,
    closed_at TIMESTAMPTZ NOT NULL,
    opening_balance BIGINT NOT NULL DEFAULT 0,
    closing_balance BIGINT NOT NULL DEFAULT 0,
    total_cash_sales BIGINT NOT NULL DEFAULT 0,
    total_qris_sales BIGINT NOT NULL DEFAULT 0,
    total_cash_in BIGINT NOT NULL DEFAULT 0,
    total_cash_out BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. RLS Policies (Enable access for authenticated users)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_item_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable ALL for Authenticated" ON public.profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.categories FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.menu_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.menu_item_variants FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.orders FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.order_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.payments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.shifts FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Enable ALL for Authenticated" ON public.store_settings FOR ALL TO authenticated USING (true) WITH CHECK (true);

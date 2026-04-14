import 'package:flow_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StoreSettingsRemoteDataSource {
  Future<StoreSettingsModel> getStoreSettings();
  Future<StoreSettingsModel> updateStoreSettings({
    String? id,
    required double taxPercentage,
    required double serviceChargePercentage,
    required String storeName,
    required String storeAddress,
    required bool isCashEnabled,
    required bool isCardEnabled,
    required bool isTransferEnabled,
    String? bankName,
    String? bankAccountNumber,
    required bool isQrisEnabled,
    String? midtransMerchantId,
    String? midtransClientKey,
    String? midtransServerKey,
    required bool isMidtransSandbox,
    String? midtransMerchantIdSandbox,
    String? midtransClientKeySandbox,
    String? midtransServerKeySandbox,
  });
}

class StoreSettingsRemoteDataSourceImpl
    implements StoreSettingsRemoteDataSource {
  final SupabaseClient supabaseClient;

  StoreSettingsRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<StoreSettingsModel> getStoreSettings() async {
    final rows = await supabaseClient
        .from('store_settings')
        .select()
        .order('updated_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return const StoreSettingsModel.zero();
    }

    return StoreSettingsModel.fromJson(rows.first);
  }

  @override
  Future<StoreSettingsModel> updateStoreSettings({
    String? id,
    required double taxPercentage,
    required double serviceChargePercentage,
    required String storeName,
    required String storeAddress,
    required bool isCashEnabled,
    required bool isCardEnabled,
    required bool isTransferEnabled,
    String? bankName,
    String? bankAccountNumber,
    required bool isQrisEnabled,
    String? midtransMerchantId,
    String? midtransClientKey,
    String? midtransServerKey,
    required bool isMidtransSandbox,
    String? midtransMerchantIdSandbox,
    String? midtransClientKeySandbox,
    String? midtransServerKeySandbox,
  }) async {
    final payload = {
      'tax_percentage': taxPercentage,
      'service_charge_percentage': serviceChargePercentage,
      'store_name': storeName,
      'store_address': storeAddress,
      'is_cash_enabled': isCashEnabled,
      'is_card_enabled': isCardEnabled,
      'is_transfer_enabled': isTransferEnabled,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'is_qris_enabled': isQrisEnabled,
      'midtrans_server_key': midtransServerKey,
      'is_midtrans_sandbox': isMidtransSandbox,
      'midtrans_merchant_id_sandbox': midtransMerchantIdSandbox,
      'midtrans_client_key_sandbox': midtransClientKeySandbox,
      'midtrans_server_key_sandbox': midtransServerKeySandbox,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (id != null && id.trim().isNotEmpty) {
      final row = await supabaseClient
          .from('store_settings')
          .update(payload)
          .eq('id', id)
          .select()
          .single();

      return StoreSettingsModel.fromJson(row);
    }

    final row = await supabaseClient
        .from('store_settings')
        .insert(payload)
        .select()
        .single();

    return StoreSettingsModel.fromJson(row);
  }
}

import 'package:flow_pos/features/menu_item/domain/entities/menu_item_variant.dart';

class MenuItemVariantModel extends MenuItemVariant {
  const MenuItemVariantModel({
    required super.id,
    required super.menuItemId,
    required super.optionName,
    required super.variantName,
    required super.price,
    super.basePrice = 0,
    required super.unit,
  });

  factory MenuItemVariantModel.fromJson(Map<String, dynamic> map) {
    return MenuItemVariantModel(
      id: map['id'] ?? '',
      menuItemId: map['menu_item_id'] ?? '',
      optionName: map['option_name'] ?? '',
      variantName: map['variant_name'] ?? '',
      price: map['price'] ?? 0,
      basePrice: map['base_price'] ?? 0,
      unit: map['unit'] ?? 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'option_name': optionName,
      'variant_name': variantName,
      'price': price,
      'base_price': basePrice,
      'unit': unit,
    };
  }
}

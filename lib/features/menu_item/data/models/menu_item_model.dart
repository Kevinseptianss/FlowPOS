import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/category/data/models/category_model.dart';
import 'package:flow_pos/features/menu_item/data/models/menu_item_variant_model.dart';

class MenuItemModel extends MenuItem {
  const MenuItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.category,
    required super.enabled,
    required super.unit,
    required super.variants,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      category: CategoryModel.fromJson(map['categories'] ?? {}),
      enabled: map['is_available'] ?? true,
      unit: map['unit'] ?? 'pcs',
      variants: (map['menu_item_variants'] as List<dynamic>? ?? [])
          .map((v) => MenuItemVariantModel.fromJson(v))
          .toList(),
    );
  }
}

import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';

class MenuItemModel extends MenuItem {
  const MenuItemModel({
    required super.id,
    required super.name,
    required super.price,
    required super.categoryId,
    required super.enabled,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? 0,
      categoryId: map['category_id'] ?? '',
      enabled: map['is_available'] ?? true,
    );
  }
}

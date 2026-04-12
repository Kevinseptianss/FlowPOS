import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item_variant.dart';

class MenuItem extends Equatable {
  final String id;
  final String name;
  final int price;
  final Category category;
  final bool enabled;
  final String unit;
  final List<MenuItemVariant> variants;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.enabled,
    this.unit = 'pcs',
    this.variants = const [],
  });

  @override
  List<Object?> get props => [id, name, price, category, enabled, unit, variants];
}

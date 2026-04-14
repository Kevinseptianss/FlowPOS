import 'package:equatable/equatable.dart';

class MenuItemVariant extends Equatable {
  final String id;
  final String menuItemId;
  final String optionName;
  final String variantName;
  final int price;
  final int basePrice;
  final String unit;

  const MenuItemVariant({
    required this.id,
    required this.menuItemId,
    required this.optionName,
    required this.variantName,
    required this.price,
    this.basePrice = 0,
    required this.unit,
  });

  @override
  List<Object?> get props => [id, menuItemId, optionName, variantName, price, basePrice, unit];
}

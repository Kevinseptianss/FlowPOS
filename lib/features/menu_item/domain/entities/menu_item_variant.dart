import 'package:equatable/equatable.dart';

class MenuItemVariant extends Equatable {
  final String id;
  final String menuItemId;
  final String optionName;
  final String variantName;
  final int price;
  final String unit;

  const MenuItemVariant({
    required this.id,
    required this.menuItemId,
    required this.optionName,
    required this.variantName,
    required this.price,
    required this.unit,
  });

  @override
  List<Object?> get props => [id, menuItemId, optionName, variantName, price, unit];
}

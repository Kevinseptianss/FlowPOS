import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String menuItemId;
  final String menuName;
  final int quantity;
  final int unitPrice;
  final String? notes;
  final String? modifierSnapshot;

  const OrderItem({
    required this.menuItemId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    this.modifierSnapshot,
  });

  @override
  List<Object?> get props => [
    menuItemId,
    menuName,
    quantity,
    unitPrice,
    notes,
    modifierSnapshot,
  ];
}

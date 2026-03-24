import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String menuItemId;
  final int quantity;
  final int unitPrice;
  final String? notes;
  final String? modifierSnapshot;

  const OrderItem({
    required this.menuItemId,
    required this.quantity,
    required this.unitPrice,
    this.notes,
    this.modifierSnapshot,
  });

  @override
  List<Object?> get props => [
    menuItemId,
    quantity,
    unitPrice,
    notes,
    modifierSnapshot,
  ];
}

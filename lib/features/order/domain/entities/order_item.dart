import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  final String menuItemId;
  final String menuName;
  final int quantity;
  final int unitPrice;
  final String? variantId; // NEW: For stock tracking
  final String? notes;
  final String? modifierSnapshot;
  final String? id; // Database ID for soft-delete logic
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? deletedById;

  const OrderItem({
    required this.menuItemId,
    required this.menuName,
    required this.quantity,
    required this.unitPrice,
    this.variantId,
    this.notes,
    this.modifierSnapshot,
    this.id,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedById,
  });

  @override
  List<Object?> get props => [
    menuItemId,
    menuName,
    quantity,
    unitPrice,
    variantId,
    notes,
    modifierSnapshot,
    id,
    isDeleted,
    deletedAt,
    deletedById,
  ];
}

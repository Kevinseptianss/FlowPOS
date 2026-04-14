import 'package:equatable/equatable.dart';

class Stock extends Equatable {
  final String id;
  final String? menuItemId;
  final String? variantId;
  final double quantity;
  final int minThreshold;
  final DateTime updatedAt;
  final bool hasPurchaseOrder; // NEW: To filter untracked items in UI
  final String itemName; // Helper for UI
  final String? variantName; // Helper for UI
  final String? categoryId; // NEW: For filtering in UI
  final int? price; // NEW: Selling Price
  final int? basePrice; // NEW: Cost (Modal)

  const Stock({
    required this.id,
    this.menuItemId,
    this.variantId,
    required this.quantity,
    required this.minThreshold,
    required this.updatedAt,
    required this.hasPurchaseOrder,
    required this.itemName,
    this.variantName,
    this.categoryId,
    this.price,
    this.basePrice,
  });

  @override
  List<Object?> get props => [
        id,
        menuItemId,
        variantId,
        quantity,
        minThreshold,
        updatedAt,
        hasPurchaseOrder,
        itemName,
        variantName,
        categoryId,
        price,
        basePrice,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';

class Cart extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final int basePrice; // Selling Price (per product)
  final int costPrice; // Cost Price (HPP per product)
  final int quantity;
  final Map<String, SelectedModifier?> selectedModifiers;
  final int totalPrice;
  final String? variantId;
  final String? notes;
  final String? modifierSnapshot; // NEW: For reloaded items

  const Cart({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.basePrice,
    required this.costPrice,
    required this.quantity,
    required this.selectedModifiers,
    required this.totalPrice,
    this.variantId,
    this.notes,
    this.modifierSnapshot,
  });

  Cart copyWith({
    String? id,
    String? menuItemId,
    String? name,
    int? basePrice,
    int? costPrice,
    int? quantity,
    Map<String, SelectedModifier?>? selectedModifiers,
    int? totalPrice,
    String? variantId,
    String? notes,
    String? modifierSnapshot,
  }) {
    return Cart(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      totalPrice: totalPrice ?? this.totalPrice,
      variantId: variantId ?? this.variantId,
      notes: notes ?? this.notes,
      modifierSnapshot: modifierSnapshot ?? this.modifierSnapshot,
    );
  }

  @override
  List<Object?> get props => [
    id,
    menuItemId,
    name,
    basePrice,
    costPrice,
    quantity,
    selectedModifiers,
    totalPrice,
    variantId,
    notes,
    modifierSnapshot,
  ];
}

import 'package:equatable/equatable.dart';

class SelectedModifier extends Equatable {
  final String id;
  final String name;

  const SelectedModifier({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class Cart extends Equatable {
  final String id;
  final String menuItemId;
  final String name;
  final int basePrice;
  final int quantity;
  final Map<String, SelectedModifier?> selectedModifiers;
  final int totalPrice;

  const Cart({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.basePrice,
    required this.quantity,
    required this.selectedModifiers,
    required this.totalPrice,
  });

  Cart copyWith({
    String? id,
    String? menuItemId,
    String? name,
    int? basePrice,
    int? quantity,
    Map<String, SelectedModifier?>? selectedModifiers,
    int? totalPrice,
  }) {
    return Cart(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      quantity: quantity ?? this.quantity,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  List<Object?> get props => [
    id,
    menuItemId,
    name,
    basePrice,
    quantity,
    selectedModifiers,
    totalPrice,
  ];
}

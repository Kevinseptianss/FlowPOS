import 'package:equatable/equatable.dart';

class ModifierOption extends Equatable {
  final String id;
  final String name;
  final int additionalPrice;
  final String modifierGroupId;
  final String modifierGroupName;

  const ModifierOption({
    required this.id,
    required this.name,
    required this.additionalPrice,
    required this.modifierGroupId,
    required this.modifierGroupName,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    additionalPrice,
    modifierGroupId,
    modifierGroupName,
  ];
}

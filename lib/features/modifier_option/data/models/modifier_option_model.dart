import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';

class ModifierOptionModel extends ModifierOption {
  const ModifierOptionModel({
    required super.id,
    required super.name,
    required super.additionalPrice,
    required super.modifierGroupId,
    required super.modifierGroupName,
  });

  factory ModifierOptionModel.fromJson(
    Map<String, dynamic> map, {
    required String modifierGroupId,
    required String modifierGroupName,
  }) {
    return ModifierOptionModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      additionalPrice: map['additional_price'] ?? 0,
      modifierGroupId: modifierGroupId,
      modifierGroupName: modifierGroupName,
    );
  }
}

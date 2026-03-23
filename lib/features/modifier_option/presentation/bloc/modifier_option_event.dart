part of 'modifier_option_bloc.dart';

sealed class ModifierOptionEvent extends Equatable {
  const ModifierOptionEvent();

  @override
  List<Object> get props => [];
}

final class GetAllModifierOptionsEvent extends ModifierOptionEvent {
  final String menuId;

  const GetAllModifierOptionsEvent({required this.menuId});

  @override
  List<Object> get props => [menuId];
}

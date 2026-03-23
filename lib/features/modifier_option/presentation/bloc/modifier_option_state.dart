part of 'modifier_option_bloc.dart';

sealed class ModifierOptionState extends Equatable {
  const ModifierOptionState();

  @override
  List<Object> get props => [];
}

final class ModifierOptionInitial extends ModifierOptionState {}

final class ModifierOptionLoading extends ModifierOptionState {}

final class ModifierOptionLoaded extends ModifierOptionState {
  final List<ModifierOption> modifierOptions;

  const ModifierOptionLoaded(this.modifierOptions);

  @override
  List<Object> get props => [modifierOptions];
}

final class ModifierOptionFailure extends ModifierOptionState {
  final String message;

  const ModifierOptionFailure(this.message);

  @override
  List<Object> get props => [message];
}

part of 'store_settings_bloc.dart';

sealed class StoreSettingsState extends Equatable {
  const StoreSettingsState();

  @override
  List<Object> get props => [];
}

final class StoreSettingsInitial extends StoreSettingsState {}

final class StoreSettingsLoading extends StoreSettingsState {}

final class StoreSettingsLoaded extends StoreSettingsState {
  final StoreSettings storeSettings;

  const StoreSettingsLoaded(this.storeSettings);

  @override
  List<Object> get props => [storeSettings];
}

final class StoreSettingsFailure extends StoreSettingsState {
  final String message;

  const StoreSettingsFailure(this.message);

  @override
  List<Object> get props => [message];
}

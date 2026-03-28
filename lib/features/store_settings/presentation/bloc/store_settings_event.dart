part of 'store_settings_bloc.dart';

sealed class StoreSettingsEvent extends Equatable {
  const StoreSettingsEvent();

  @override
  List<Object> get props => [];
}

final class StartStoreSettingsRealtimeEvent extends StoreSettingsEvent {}

final class StopStoreSettingsRealtimeEvent extends StoreSettingsEvent {}

final class UpdateStoreSettingsEvent extends StoreSettingsEvent {
  final String? id;
  final double taxPercentage;
  final double serviceChargePercentage;

  const UpdateStoreSettingsEvent({
    this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
  });

  @override
  List<Object> get props => [id ?? '', taxPercentage, serviceChargePercentage];
}

final class StoreSettingsRealtimeUpdatedEvent extends StoreSettingsEvent {
  final StoreSettings storeSettings;

  const StoreSettingsRealtimeUpdatedEvent(this.storeSettings);

  @override
  List<Object> get props => [storeSettings];
}

final class StoreSettingsRealtimeFailureEvent extends StoreSettingsEvent {
  final String message;

  const StoreSettingsRealtimeFailureEvent(this.message);

  @override
  List<Object> get props => [message];
}

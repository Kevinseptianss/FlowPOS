part of 'store_settings_bloc.dart';

sealed class StoreSettingsEvent extends Equatable {
  const StoreSettingsEvent();

  @override
  List<Object> get props => [];
}

final class GetStoreSettingsEvent extends StoreSettingsEvent {}

final class UpdateStoreSettingsEvent extends StoreSettingsEvent {
  final String? id;
  final double taxPercentage;
  final double serviceChargePercentage;
  final String storeName;
  final String storeAddress;

  const UpdateStoreSettingsEvent({
    this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.storeName,
    required this.storeAddress,
  });

  @override
  List<Object> get props => [
    id ?? '',
    taxPercentage,
    serviceChargePercentage,
    storeName,
    storeAddress,
  ];
}

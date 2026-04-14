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
  final bool? isCashEnabled;
  final bool? isCardEnabled;
  final bool? isTransferEnabled;
  final String? bankName;
  final String? bankAccountNumber;
  final bool? isQrisEnabled;
  final String? midtransMerchantId;
  final String? midtransClientKey;
  final String? midtransServerKey;
  final bool? isMidtransSandbox;
  final String? midtransMerchantIdSandbox;
  final String? midtransClientKeySandbox;
  final String? midtransServerKeySandbox;

  const UpdateStoreSettingsEvent({
    this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.storeName,
    required this.storeAddress,
    this.isCashEnabled,
    this.isCardEnabled,
    this.isTransferEnabled,
    this.bankName,
    this.bankAccountNumber,
    this.isQrisEnabled,
    this.midtransMerchantId,
    this.midtransClientKey,
    this.midtransServerKey,
    this.isMidtransSandbox,
    this.midtransMerchantIdSandbox,
    this.midtransClientKeySandbox,
    this.midtransServerKeySandbox,
  });

  @override
  List<Object> get props => [
    id ?? '',
    taxPercentage,
    serviceChargePercentage,
    storeName,
    storeAddress,
    isCashEnabled ?? true,
    isCardEnabled ?? true,
    isTransferEnabled ?? false,
    bankName ?? '',
    bankAccountNumber ?? '',
    isQrisEnabled ?? false,
    midtransMerchantId ?? '',
    midtransClientKey ?? '',
    midtransServerKey ?? '',
    isMidtransSandbox ?? true,
    midtransMerchantIdSandbox ?? '',
    midtransClientKeySandbox ?? '',
    midtransServerKeySandbox ?? '',
  ];
}

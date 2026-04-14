import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateStoreSettings
    implements UseCase<StoreSettings, UpdateStoreSettingsParams> {
  final StoreSettingsRepository storeSettingsRepository;

  const UpdateStoreSettings(this.storeSettingsRepository);

  @override
  Future<Either<Failure, StoreSettings>> call(
    UpdateStoreSettingsParams params,
  ) {
    return storeSettingsRepository.updateStoreSettings(
      id: params.id,
      taxPercentage: params.taxPercentage,
      serviceChargePercentage: params.serviceChargePercentage,
      storeName: params.storeName,
      storeAddress: params.storeAddress,
      isCashEnabled: params.isCashEnabled,
      isCardEnabled: params.isCardEnabled,
      isTransferEnabled: params.isTransferEnabled,
      bankName: params.bankName,
      bankAccountNumber: params.bankAccountNumber,
      isQrisEnabled: params.isQrisEnabled,
      midtransMerchantId: params.midtransMerchantId,
      midtransClientKey: params.midtransClientKey,
      midtransServerKey: params.midtransServerKey,
      isMidtransSandbox: params.isMidtransSandbox,
      midtransMerchantIdSandbox: params.midtransMerchantIdSandbox,
      midtransClientKeySandbox: params.midtransClientKeySandbox,
      midtransServerKeySandbox: params.midtransServerKeySandbox,
    );
  }
}

class UpdateStoreSettingsParams {
  final String? id;
  final double taxPercentage;
  final double serviceChargePercentage;
  final String storeName;
  final String storeAddress;
  final bool isCashEnabled;
  final bool isCardEnabled;
  final bool isTransferEnabled;
  final String? bankName;
  final String? bankAccountNumber;
  final bool isQrisEnabled;
  final String? midtransMerchantId;
  final String? midtransClientKey;
  final String? midtransServerKey;
  final bool isMidtransSandbox;
  final String? midtransMerchantIdSandbox;
  final String? midtransClientKeySandbox;
  final String? midtransServerKeySandbox;

  const UpdateStoreSettingsParams({
    this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.storeName,
    required this.storeAddress,
    required this.isCashEnabled,
    required this.isCardEnabled,
    required this.isTransferEnabled,
    this.bankName,
    this.bankAccountNumber,
    required this.isQrisEnabled,
    this.midtransMerchantId,
    this.midtransClientKey,
    this.midtransServerKey,
    required this.isMidtransSandbox,
    this.midtransMerchantIdSandbox,
    this.midtransClientKeySandbox,
    this.midtransServerKeySandbox,
  });
}

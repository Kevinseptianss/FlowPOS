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
    );
  }
}

class UpdateStoreSettingsParams {
  final String? id;
  final double taxPercentage;
  final double serviceChargePercentage;
  final String storeName;
  final String storeAddress;

  const UpdateStoreSettingsParams({
    this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.storeName,
    required this.storeAddress,
  });
}

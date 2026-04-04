import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetStoreSettings implements UseCase<StoreSettings, NoParams> {
  final StoreSettingsRepository storeSettingsRepository;

  const GetStoreSettings(this.storeSettingsRepository);

  @override
  Future<Either<Failure, StoreSettings>> call(NoParams params) {
    return storeSettingsRepository.getStoreSettings();
  }
}

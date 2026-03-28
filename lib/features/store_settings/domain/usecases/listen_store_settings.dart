import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:fpdart/fpdart.dart';

class ListenStoreSettings {
  final StoreSettingsRepository storeSettingsRepository;

  const ListenStoreSettings(this.storeSettingsRepository);

  Stream<Either<Failure, StoreSettings>> call() {
    return storeSettingsRepository.listenStoreSettings();
  }
}

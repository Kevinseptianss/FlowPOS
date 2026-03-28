import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class StoreSettingsRepository {
  Stream<Either<Failure, StoreSettings>> listenStoreSettings();
}

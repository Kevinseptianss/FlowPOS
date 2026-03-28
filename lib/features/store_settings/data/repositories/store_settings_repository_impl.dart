import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/store_settings/data/datasources/store_settings_remote_data_source.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/repositories/store_settings_repository.dart';
import 'package:fpdart/fpdart.dart';

class StoreSettingsRepositoryImpl implements StoreSettingsRepository {
  final StoreSettingsRemoteDataSource storeSettingsRemoteDataSource;

  StoreSettingsRepositoryImpl(this.storeSettingsRemoteDataSource);

  @override
  Stream<Either<Failure, StoreSettings>> listenStoreSettings() async* {
    try {
      await for (final storeSettings
          in storeSettingsRemoteDataSource.listenStoreSettings()) {
        yield right(storeSettings);
      }
    } on ServerException catch (e) {
      yield left(Failure(e.message));
    } catch (e) {
      yield left(Failure(e.toString()));
    }
  }
}

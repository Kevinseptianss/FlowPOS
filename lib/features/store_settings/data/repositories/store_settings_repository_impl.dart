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
  Future<Either<Failure, StoreSettings>> getStoreSettings() async {
    try {
      final storeSettings = await storeSettingsRemoteDataSource
          .getStoreSettings();
      return right(storeSettings);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StoreSettings>> updateStoreSettings({
    String? id,
    required double taxPercentage,
    required double serviceChargePercentage,
    required String storeName,
    required String storeAddress,
  }) async {
    try {
      final updated = await storeSettingsRemoteDataSource.updateStoreSettings(
        id: id,
        taxPercentage: taxPercentage,
        serviceChargePercentage: serviceChargePercentage,
        storeName: storeName,
        storeAddress: storeAddress,
      );

      return right(updated);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

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
    required bool isCashEnabled,
    required bool isCardEnabled,
    required bool isTransferEnabled,
    String? bankName,
    String? bankAccountNumber,
    required bool isQrisEnabled,
    String? midtransMerchantId,
    String? midtransClientKey,
    String? midtransServerKey,
    required bool isMidtransSandbox,
    String? midtransMerchantIdSandbox,
    String? midtransClientKeySandbox,
    String? midtransServerKeySandbox,
  }) async {
    try {
      final updated = await storeSettingsRemoteDataSource.updateStoreSettings(
        id: id,
        taxPercentage: taxPercentage,
        serviceChargePercentage: serviceChargePercentage,
        storeName: storeName,
        storeAddress: storeAddress,
        isCashEnabled: isCashEnabled,
        isCardEnabled: isCardEnabled,
        isTransferEnabled: isTransferEnabled,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        isQrisEnabled: isQrisEnabled,
        midtransMerchantId: midtransMerchantId,
        midtransClientKey: midtransClientKey,
        midtransServerKey: midtransServerKey,
        isMidtransSandbox: isMidtransSandbox,
        midtransMerchantIdSandbox: midtransMerchantIdSandbox,
        midtransClientKeySandbox: midtransClientKeySandbox,
        midtransServerKeySandbox: midtransServerKeySandbox,
      );

      return right(updated);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

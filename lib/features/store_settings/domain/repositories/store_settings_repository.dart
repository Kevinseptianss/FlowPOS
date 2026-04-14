import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class StoreSettingsRepository {
  Future<Either<Failure, StoreSettings>> getStoreSettings();
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
  });
}

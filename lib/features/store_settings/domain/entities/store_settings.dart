import 'package:equatable/equatable.dart';

class StoreSettings extends Equatable {
  final String id;
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

  const StoreSettings({
    required this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.storeName,
    required this.storeAddress,
    this.isCashEnabled = true,
    this.isCardEnabled = true,
    this.isTransferEnabled = false,
    this.bankName,
    this.bankAccountNumber,
    this.isQrisEnabled = false,
    this.midtransMerchantId,
    this.midtransClientKey,
    this.midtransServerKey,
    this.isMidtransSandbox = true,
    this.midtransMerchantIdSandbox,
    this.midtransClientKeySandbox,
    this.midtransServerKeySandbox,
  });

  const StoreSettings.zero()
    : id = '',
      taxPercentage = 0,
      serviceChargePercentage = 0,
      storeName = 'FlowPOS',
      storeAddress = 'No Address',
      isCashEnabled = true,
      isCardEnabled = true,
      isTransferEnabled = false,
      bankName = '',
      bankAccountNumber = '',
      isQrisEnabled = false,
      midtransMerchantId = '',
      midtransClientKey = '',
      midtransServerKey = '',
      isMidtransSandbox = true,
      midtransMerchantIdSandbox = '',
      midtransClientKeySandbox = '',
      midtransServerKeySandbox = '';

  @override
  List<Object?> get props => [
    id,
    taxPercentage,
    serviceChargePercentage,
    storeName,
    storeAddress,
    isCashEnabled,
    isCardEnabled,
    isTransferEnabled,
    bankName,
    bankAccountNumber,
    isQrisEnabled,
    midtransMerchantId,
    midtransClientKey,
    midtransServerKey,
    isMidtransSandbox,
    midtransMerchantIdSandbox,
    midtransClientKeySandbox,
    midtransServerKeySandbox,
  ];
}

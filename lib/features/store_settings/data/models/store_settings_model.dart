import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';

class StoreSettingsModel extends StoreSettings {
  const StoreSettingsModel({
    required super.id,
    required super.taxPercentage,
    required super.serviceChargePercentage,
    required super.storeName,
    required super.storeAddress,
    super.isCashEnabled = true,
    super.isCardEnabled = true,
    super.isTransferEnabled = false,
    super.bankName = '',
    super.bankAccountNumber = '',
    super.isQrisEnabled = false,
    super.midtransMerchantId = '',
    super.midtransClientKey = '',
    super.midtransServerKey = '',
    super.isMidtransSandbox = true,
    super.midtransMerchantIdSandbox = '',
    super.midtransClientKeySandbox = '',
    super.midtransServerKeySandbox = '',
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> map) {
    return StoreSettingsModel(
      id: map['id'] as String? ?? '',
      taxPercentage: (map['tax_percentage'] as num?)?.toDouble() ?? 0,
      serviceChargePercentage:
          (map['service_charge_percentage'] as num?)?.toDouble() ?? 0,
      storeName: map['store_name'] as String? ?? 'FlowPOS',
      storeAddress: map['store_address'] as String? ?? 'No Address',
      isCashEnabled: map['is_cash_enabled'] as bool? ?? true,
      isCardEnabled: map['is_card_enabled'] as bool? ?? true,
      isTransferEnabled: map['is_transfer_enabled'] as bool? ?? false,
      bankName: map['bank_name'] as String? ?? '',
      bankAccountNumber: map['bank_account_number'] as String? ?? '',
      isQrisEnabled: map['is_qris_enabled'] as bool? ?? false,
      midtransMerchantId: map['midtrans_merchant_id'] as String? ?? '',
      midtransClientKey: map['midtrans_client_key'] as String? ?? '',
      midtransServerKey: map['midtrans_server_key'] as String? ?? '',
      isMidtransSandbox: map['is_midtrans_sandbox'] as bool? ?? true,
      midtransMerchantIdSandbox: map['midtrans_merchant_id_sandbox'] as String? ?? '',
      midtransClientKeySandbox: map['midtrans_client_key_sandbox'] as String? ?? '',
      midtransServerKeySandbox: map['midtrans_server_key_sandbox'] as String? ?? '',
    );
  }

  const StoreSettingsModel.zero()
    : this(
        id: '',
        taxPercentage: 0,
        serviceChargePercentage: 0,
        storeName: 'FlowPOS',
        storeAddress: 'No Address',
        isCashEnabled: true,
        isCardEnabled: true,
        isTransferEnabled: false,
        bankName: '',
        bankAccountNumber: '',
        isQrisEnabled: false,
        midtransMerchantId: '',
        midtransClientKey: '',
        midtransServerKey: '',
        isMidtransSandbox: true,
        midtransMerchantIdSandbox: '',
        midtransClientKeySandbox: '',
        midtransServerKeySandbox: '',
      );
}

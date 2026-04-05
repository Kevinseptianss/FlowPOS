import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';

class StoreSettingsModel extends StoreSettings {
  const StoreSettingsModel({
    required super.id,
    required super.taxPercentage,
    required super.serviceChargePercentage,
    required super.storeName,
    required super.storeAddress,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> map) {
    return StoreSettingsModel(
      id: map['id'] as String? ?? '',
      taxPercentage: (map['tax_percentage'] as num?)?.toDouble() ?? 0,
      serviceChargePercentage:
          (map['service_charge_percentage'] as num?)?.toDouble() ?? 0,
      storeName: map['store_name'] as String? ?? 'FlowPOS',
      storeAddress: map['store_address'] as String? ?? 'No Address',
    );
  }

  const StoreSettingsModel.zero()
    : this(
        id: '',
        taxPercentage: 0,
        serviceChargePercentage: 0,
        storeName: 'FlowPOS',
        storeAddress: 'No Address',
      );
}

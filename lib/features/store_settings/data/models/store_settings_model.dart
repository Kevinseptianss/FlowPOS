import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';

class StoreSettingsModel extends StoreSettings {
  const StoreSettingsModel({
    required super.id,
    required super.taxPercentage,
    required super.serviceChargePercentage,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> map) {
    return StoreSettingsModel(
      id: map['id'] as String? ?? '',
      taxPercentage: (map['tax_percentage'] as num?)?.toDouble() ?? 0,
      serviceChargePercentage:
          (map['service_charge_percentage'] as num?)?.toDouble() ?? 0,
    );
  }

  const StoreSettingsModel.zero()
    : this(id: '', taxPercentage: 0, serviceChargePercentage: 0);
}

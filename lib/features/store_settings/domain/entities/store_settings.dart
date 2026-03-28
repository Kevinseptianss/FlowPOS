import 'package:equatable/equatable.dart';

class StoreSettings extends Equatable {
  final String id;
  final double taxPercentage;
  final double serviceChargePercentage;

  const StoreSettings({
    required this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
  });

  const StoreSettings.zero()
    : id = '',
      taxPercentage = 0,
      serviceChargePercentage = 0;

  @override
  List<Object?> get props => [id, taxPercentage, serviceChargePercentage];
}

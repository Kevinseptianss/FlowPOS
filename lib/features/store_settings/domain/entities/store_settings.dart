import 'package:equatable/equatable.dart';

class StoreSettings extends Equatable {
  final String id;
  final double taxPercentage;
  final double serviceChargePercentage;
  final String storeName;
  final String storeAddress;

  const StoreSettings({
    required this.id,
    required this.taxPercentage,
    required this.serviceChargePercentage,
    required this.storeName,
    required this.storeAddress,
  });

  const StoreSettings.zero()
    : id = '',
      taxPercentage = 0,
      serviceChargePercentage = 0,
      storeName = 'FlowPOS',
      storeAddress = 'No Address';

  @override
  List<Object?> get props => [
    id,
    taxPercentage,
    serviceChargePercentage,
    storeName,
    storeAddress,
  ];
}

import 'package:equatable/equatable.dart';

class MonthlyRevenue extends Equatable {
  final int totalRevenue;
  final int totalQrisRevenue;
  final int totalCashRevenue;
  final int totalTransferRevenue;
  final int totalCardRevenue;
  final int totalOrders;

  const MonthlyRevenue({
    required this.totalRevenue,
    required this.totalQrisRevenue,
    required this.totalCashRevenue,
    required this.totalTransferRevenue,
    required this.totalCardRevenue,
    required this.totalOrders,
  });

  const MonthlyRevenue.empty()
    : totalRevenue = 0,
      totalQrisRevenue = 0,
      totalCashRevenue = 0,
      totalTransferRevenue = 0,
      totalCardRevenue = 0,
      totalOrders = 0;

  @override
  List<Object?> get props => [
    totalRevenue,
    totalQrisRevenue,
    totalCashRevenue,
    totalTransferRevenue,
    totalCardRevenue,
    totalOrders,
  ];
}

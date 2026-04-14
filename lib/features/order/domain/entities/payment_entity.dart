import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String orderId;
  final String method;
  final int amountPaid;
  final int amountDue;
  final int changeGiven;

  const PaymentEntity({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amountPaid,
    required this.amountDue,
    required this.changeGiven,
  });

  @override
  List<Object?> get props => [
    id,
    orderId,
    method,
    amountPaid,
    amountDue,
    changeGiven,
  ];
}

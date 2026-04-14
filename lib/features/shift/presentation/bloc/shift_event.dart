part of 'shift_bloc.dart';

sealed class ShiftEvent extends Equatable {
  const ShiftEvent();

  @override
  List<Object> get props => [];
}

class GetShiftHistoryEvent extends ShiftEvent {}

class OpenShiftEvent extends ShiftEvent {
  final String cashierId;
  final String cashierName;
  final double openingBalance;

  const OpenShiftEvent({
    required this.cashierId,
    required this.cashierName,
    required this.openingBalance,
  });

  @override
  List<Object> get props => [cashierId, cashierName, openingBalance];
}


class CloseShiftEvent extends ShiftEvent {
  final String cashierId;
  final double closingBalance;

  const CloseShiftEvent({
    required this.cashierId,
    required this.closingBalance,
  });

  @override
  List<Object> get props => [cashierId, closingBalance];
}

class GetActiveShiftEvent extends ShiftEvent {
  final String cashierId;
  const GetActiveShiftEvent({required this.cashierId});

  @override
  List<Object> get props => [cashierId];
}

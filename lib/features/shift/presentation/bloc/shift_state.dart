part of 'shift_bloc.dart';

sealed class ShiftState extends Equatable {
  const ShiftState();
  
  @override
  List<Object> get props => [];
}

final class ShiftInitial extends ShiftState {}

final class ShiftLoading extends ShiftState {}

final class ShiftLoaded extends ShiftState {
  final List<ShiftEntity> shifts;
  const ShiftLoaded(this.shifts);

  @override
  List<Object> get props => [shifts];
}

final class ShiftFailure extends ShiftState {
  final String message;
  const ShiftFailure(this.message);

  @override
  List<Object> get props => [message];
}

final class ShiftOpened extends ShiftState {
  final ShiftEntity shift;
  const ShiftOpened(this.shift);

  @override
  List<Object> get props => [shift];
}

final class ShiftNone extends ShiftState {}

final class ShiftSkipped extends ShiftState {}

final class ShiftClosed extends ShiftState {
  final ShiftEntity shift;
  const ShiftClosed(this.shift);

  @override
  List<Object> get props => [shift];
}

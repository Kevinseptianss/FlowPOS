part of 'staff_bloc.dart';

sealed class StaffState extends Equatable {
  const StaffState();
  
  @override
  List<Object> get props => [];
}

final class StaffInitial extends StaffState {}

final class StaffLoading extends StaffState {}

final class StaffLoaded extends StaffState {
  final List<StaffProfile> staff;
  const StaffLoaded(this.staff);

  @override
  List<Object> get props => [staff];
}

final class StaffFailure extends StaffState {
  final String message;
  const StaffFailure(this.message);

  @override
  List<Object> get props => [message];
}

final class StaffRoleUpdated extends StaffState {
  final StaffProfile staff;
  const StaffRoleUpdated(this.staff);

  @override
  List<Object> get props => [staff];
}

final class StaffCreated extends StaffState {
  final StaffProfile staff;
  const StaffCreated(this.staff);

  @override
  List<Object> get props => [staff];
}

final class StaffDeleted extends StaffState {}

final class UsernameChecked extends StaffState {
  final bool exists;
  const UsernameChecked(this.exists);

  @override
  List<Object> get props => [exists];
}

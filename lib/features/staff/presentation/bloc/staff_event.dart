part of 'staff_bloc.dart';

sealed class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

class GetStaffEvent extends StaffEvent {}

class UpdateStaffRoleEvent extends StaffEvent {
  final String staffId;
  final String role;
  const UpdateStaffRoleEvent(this.staffId, this.role);

  @override
  List<Object> get props => [staffId, role];
}

class CreateStaffEvent extends StaffEvent {
  final String name;
  final String username;
  final String password;
  const CreateStaffEvent({
    required this.name,
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [name, username, password];
}

class DeleteStaffEvent extends StaffEvent {
  final String staffId;
  const DeleteStaffEvent(this.staffId);

  @override
  List<Object> get props => [staffId];
}

class CheckUsernameEvent extends StaffEvent {
  final String username;
  const CheckUsernameEvent(this.username);

  @override
  List<Object> get props => [username];
}

class UpdateStaffSalaryEvent extends StaffEvent {
  final String staffId;
  final int? salary;
  final String? salaryType;
  final int? hourlyRate;
  final int? minuteRate;

  const UpdateStaffSalaryEvent({
    required this.staffId,
    this.salary,
    this.salaryType,
    this.hourlyRate,
    this.minuteRate,
  });

  @override
  List<Object?> get props => [staffId, salary, salaryType, hourlyRate, minuteRate];
}

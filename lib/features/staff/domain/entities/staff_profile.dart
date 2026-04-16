import 'package:equatable/equatable.dart';

class StaffProfile extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? username;
  final DateTime? createdAt;

  final bool? _isActive;
  bool get isActive => _isActive ?? true;

  final int? salary;
  final String? salaryType; // 'fixed' or 'shift'
  final int? hourlyRate;
  final int? minuteRate;

  const StaffProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.username,
    this.createdAt,
    this.salary,
    this.salaryType = 'fixed',
    this.hourlyRate,
    this.minuteRate,
    bool? isActive,
  }) : _isActive = isActive ?? true;

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        createdAt,
        _isActive,
        salary,
        salaryType,
        hourlyRate,
        minuteRate,
      ];
}

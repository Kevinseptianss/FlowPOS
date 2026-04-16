import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/features/staff/domain/entities/staff_profile.dart';

class StaffModel extends StaffProfile {
  const StaffModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.username,
    super.createdAt,
    super.isActive = true,
    super.salary,
    super.salaryType = 'fixed',
    super.hourlyRate,
    super.minuteRate,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Staff',
      role: json['role'] as String? ?? 'cashier',
      username: json['username'] as String?,
      createdAt: json['created_at'] != null 
          ? _parseDate(json['created_at']) 
          : null,
      isActive: json['is_active'] as bool? ?? true,
      salary: json['salary'] as int?,
      salaryType: json['salary_type'] as String? ?? 'fixed',
      hourlyRate: json['hourly_rate'] as int?,
      minuteRate: json['minute_rate'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'username': username,
      'is_active': isActive,
      'salary': salary,
      'salary_type': salaryType,
      'hourly_rate': hourlyRate,
      'minute_rate': minuteRate,
    };
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }
}

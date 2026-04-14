import 'package:flow_pos/features/staff/domain/entities/staff_profile.dart';

class StaffModel extends StaffProfile {
  const StaffModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.username,
    super.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Staff',
      role: json['role'] as String? ?? 'cashier',
      username: json['username'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'username': username,
    };
  }
}

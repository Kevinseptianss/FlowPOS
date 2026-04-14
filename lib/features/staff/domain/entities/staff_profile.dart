import 'package:equatable/equatable.dart';

class StaffProfile extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? username;
  final DateTime? createdAt;

  const StaffProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.username,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, role, createdAt];
}

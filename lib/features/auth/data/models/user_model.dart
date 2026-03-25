import 'package:flow_pos/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    final metadata = map['user_metadata'] as Map<String, dynamic>?;

    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: (map['name'] ?? metadata?['name'] ?? '').toString(),
      role: (map['role'] ?? metadata?['role'] ?? '').toString(),
    );
  }

  UserModel copyWith({String? id, String? email, String? name, String? role}) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }
}

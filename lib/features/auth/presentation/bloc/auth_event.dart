part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

final class SignUpEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String role;

  const SignUpEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  @override
  List<Object> get props => [name, email, password, role];
}

final class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

final class IsLoggedInEvent extends AuthEvent {}

final class SignOutEvent extends AuthEvent {}

final class AuthChangePasswordEvent extends AuthEvent {
  final String newPassword;
  const AuthChangePasswordEvent({required this.newPassword});

  @override
  List<Object> get props => [newPassword];
}

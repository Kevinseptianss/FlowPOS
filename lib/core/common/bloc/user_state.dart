part of 'user_bloc.dart';

sealed class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

final class UserInitial extends UserState {}

final class UserLoggedIn extends UserState {
  final User user;
  const UserLoggedIn(this.user);

  @override
  List<Object> get props => [user];
}

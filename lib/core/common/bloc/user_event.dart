part of 'user_bloc.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

final class UserUpdateEvent extends UserEvent {
  final User? user;
  const UserUpdateEvent(this.user);
}

final class UserLogoutEvent extends UserEvent {}

import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<UserUpdateEvent>(_onUserUpdate);
    on<UserLogoutEvent>(_onUserLogout);
  }

  void _onUserUpdate(UserUpdateEvent event, Emitter<UserState> emit) {
    if (event.user == null) {
      emit(UserInitial());
    } else {
      emit(UserLoggedIn(event.user!));
    }
  }

  void _onUserLogout(UserLogoutEvent event, Emitter<UserState> emit) {
    emit(UserInitial());
  }
}

import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/domain/usecases/current_user.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_in.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_up.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUp _signUp;
  final SignIn _signIn;
  final CurrentUser _currentUser;
  final UserBloc _userBloc;

  AuthBloc({
    required SignUp signUp,
    required SignIn signIn,
    required CurrentUser currentUser,
    required UserBloc userBloc,
  }) : _signUp = signUp,
       _signIn = signIn,
       _currentUser = currentUser,
       _userBloc = userBloc,
       super(AuthInitial()) {
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<IsLoggedInEvent>(_onIsLoggedIn);
  }

  void _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _signUp(
      SignUpParams(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => _emitSuccess(emit, r),
    );
  }

  void _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );

    result.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => _emitSuccess(emit, r),
    );
  }

  void _onIsLoggedIn(IsLoggedInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _currentUser(NoParams());

    result.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => _emitSuccess(emit, r),
    );
  }

  void _emitSuccess(Emitter<AuthState> emit, User user) {
    _userBloc.add(UserUpdateEvent(user));
    emit(AuthSuccess());
  }
}

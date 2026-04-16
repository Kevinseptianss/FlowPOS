import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/domain/usecases/current_user.dart';
import 'package:flow_pos/features/auth/domain/usecases/logout.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_in.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_up.dart';
import 'package:flow_pos/features/auth/domain/usecases/change_password.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUp _signUp;
  final SignIn _signIn;
  final CurrentUser _currentUser;
  final Logout _logout;
  final ChangePassword _changePassword;
  final UserBloc _userBloc;

  AuthBloc({
    required SignUp signUp,
    required SignIn signIn,
    required CurrentUser currentUser,
    required Logout logout,
    required ChangePassword changePassword,
    required UserBloc userBloc,
  }) : _signUp = signUp,
       _signIn = signIn,
       _currentUser = currentUser,
       _logout = logout,
       _changePassword = changePassword,
       _userBloc = userBloc,
       super(AuthInitial()) {
    on<SignUpEvent>(_onSignUp);
    on<SignInEvent>(_onSignIn);
    on<IsLoggedInEvent>(_onIsLoggedIn);
    on<SignOutEvent>(_onSignOut);
    on<AuthChangePasswordEvent>(_onChangePassword);
  }

  void _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _signUp(
      SignUpParams(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
      ),
    );

    await result.fold(
      (l) async => emit(AuthFailure(l.message)),
      (r) async {
        // Automatically logged in after sign up by Firebase, 
        // but we log out to force manual login as requested.
        await _logout(NoParams());
        if (!emit.isDone) {
          emit(AuthSignUpSuccess());
        }
      },
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
      (l) {
        if (l.message == 'No user logged in') {
          emit(AuthInitial());
        } else {
          emit(AuthFailure(l.message));
        }
      },
      (r) {
        _emitSuccess(emit, r);
        // Force the app to transition to AuthSuccess after updating UserBloc
        emit(AuthSuccess());
      },
    );
  }

  void _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _logout(NoParams());

    result.fold((l) => emit(AuthFailure(l.message)), (r) {
      _userBloc.add(UserLogoutEvent());
      emit(AuthInitial());
    });
  }

  void _onChangePassword(AuthChangePasswordEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await _changePassword(
      ChangePasswordParams(newPassword: event.newPassword),
    );

    result.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => emit(AuthPasswordChangedSuccess()),
    );
  }

  void _emitSuccess(Emitter<AuthState> emit, User user) {
    _userBloc.add(UserUpdateEvent(user));
    emit(AuthSuccess());
  }
}

import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class SignIn implements UseCase<User, SignInParams> {
  final AuthRepository authRepository;
  const SignIn(this.authRepository);

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    return await authRepository.signInWithEmailAndPassword(
      params.email,
      params.password,
    );
  }
}

class SignInParams {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});
}

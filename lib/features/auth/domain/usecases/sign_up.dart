import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class SignUp implements UseCase<User, SignUpParams> {
  final AuthRepository authRepository;
  const SignUp(this.authRepository);

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    return await authRepository.signUpWithEmailAndPassword(
      params.name,
      params.email,
      params.password,
      role: params.role,
    );
  }
}

class SignUpParams {
  final String name;
  final String email;
  final String password;
  final String role;

  const SignUpParams({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}

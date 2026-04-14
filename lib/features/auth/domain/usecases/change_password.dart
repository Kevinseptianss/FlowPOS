import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class ChangePassword implements UseCase<void, ChangePasswordParams> {
  final AuthRepository authRepository;
  ChangePassword(this.authRepository);

  @override
  Future<Either<Failure, void>> call(ChangePasswordParams params) async {
    return await authRepository.updatePassword(params.newPassword);
  }
}

class ChangePasswordParams {
  final String newPassword;
  ChangePasswordParams({required this.newPassword});
}

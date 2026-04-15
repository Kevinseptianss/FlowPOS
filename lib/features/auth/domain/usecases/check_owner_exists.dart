import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class CheckOwnerExists implements UseCase<bool, NoParams> {
  final AuthRepository authRepository;
  CheckOwnerExists(this.authRepository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await authRepository.checkOwnerExists();
  }
}

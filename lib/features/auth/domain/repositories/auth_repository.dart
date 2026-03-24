import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> signUpWithEmailAndPassword(
    String name,
    String email,
    String password,
  );
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<Either<Failure, User>> getCurrentUserData();
  Future<Either<Failure, void>> signOut();
}

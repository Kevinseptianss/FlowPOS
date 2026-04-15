import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  AuthRepositoryImpl(this.authRemoteDataSource);

  @override
  Future<Either<Failure, User>> getCurrentUserData() async {
    try {
      final user = await authRemoteDataSource.getCurrentUserData();
      if (user == null) {
        return left(Failure('No user logged in'));
      }

      return right(user);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _getUser(
      () async => await authRemoteDataSource.signInWithEmailAndPassword(
        email,
        password,
      ),
    );
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword(
    String name,
    String email,
    String password, {
    String role = 'owner',
  }) {
    return _getUser(
      () async => await authRemoteDataSource.signUpWithEmailAndPassword(
        name,
        email,
        password,
        role: role,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authRemoteDataSource.signOut();
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      await authRemoteDataSource.updatePassword(newPassword);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  Future<Either<Failure, User>> _getUser(Future<User> Function() fn) async {
    try {
      final user = await fn();
      return right(user);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> checkOwnerExists() async {
    try {
      final result = await authRemoteDataSource.checkOwnerExists();
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}

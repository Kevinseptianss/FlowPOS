import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/shift/data/datasources/shift_remote_data_source.dart';
import 'package:flow_pos/features/shift/domain/entities/shift_entity.dart';
import 'package:flow_pos/features/shift/domain/repositories/shift_repository.dart';
import 'package:fpdart/fpdart.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftRemoteDataSource remoteDataSource;
  ShiftRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ShiftEntity>>> getShiftHistory() async {
    try {
      final shifts = await remoteDataSource.getShiftHistory();
      return right(shifts);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, ShiftEntity>> openShift({
    required String cashierId,
    required double openingBalance,
  }) async {
    try {
      final shift = await remoteDataSource.openShift(
        cashierId: cashierId,
        openingBalance: openingBalance,
      );
      return right(shift);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, ShiftEntity>> closeShift({
    required String shiftId,
    required double closingBalance,
  }) async {
    try {
      final shift = await remoteDataSource.closeShift(
        shiftId: shiftId,
        closingBalance: closingBalance,
      );
      return right(shift);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String cashierId) async {
    try {
      final shift = await remoteDataSource.getActiveShift(cashierId);
      return right(shift);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ShiftEntity>>> getShiftsByRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final shifts = await remoteDataSource.getShiftsByRange(start, end);
      return right(shifts);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}

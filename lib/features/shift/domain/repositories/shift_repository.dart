import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/shift/domain/entities/shift_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ShiftRepository {
  Future<Either<Failure, List<ShiftEntity>>> getShiftHistory();
  Future<Either<Failure, ShiftEntity>> openShift({
    required String cashierId,
    required double openingBalance,
  });
  Future<Either<Failure, ShiftEntity>> closeShift({
    required String shiftId,
    required double closingBalance,
  });
  Future<Either<Failure, ShiftEntity?>> getActiveShift(String cashierId);
  Future<Either<Failure, List<ShiftEntity>>> getShiftsByRange(DateTime start, DateTime end);
}

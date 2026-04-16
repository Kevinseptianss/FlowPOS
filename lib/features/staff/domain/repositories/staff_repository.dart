import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/staff/domain/entities/staff_profile.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class StaffRepository {
  Future<Either<Failure, List<StaffProfile>>> getStaff();
  Future<Either<Failure, StaffProfile>> updateStaffRole(String staffId, String role);
  Future<Either<Failure, StaffProfile>> createStaff(String name, String username, String password);
  Future<Either<Failure, void>> deleteStaff(String staffId);
  Future<Either<Failure, bool>> checkUsername(String username);
  Future<Either<Failure, StaffProfile>> updateStaffSalary({
    required String staffId,
    int? salary,
    String? salaryType,
    int? hourlyRate,
    int? minuteRate,
  });
}

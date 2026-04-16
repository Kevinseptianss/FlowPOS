import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/staff/data/datasources/staff_remote_data_source.dart';
import 'package:flow_pos/features/staff/domain/entities/staff_profile.dart';
import 'package:flow_pos/features/staff/domain/repositories/staff_repository.dart';
import 'package:fpdart/fpdart.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffRemoteDataSource remoteDataSource;
  StaffRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<StaffProfile>>> getStaff() async {
    try {
      final staff = await remoteDataSource.getStaff();
      return right(staff);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, StaffProfile>> updateStaffRole(
    String staffId,
    String role,
  ) async {
    try {
      final staff = await remoteDataSource.updateStaffRole(staffId, role);
      return right(staff);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, StaffProfile>> createStaff(
    String name,
    String username,
    String password,
  ) async {
    try {
      final staff = await remoteDataSource.createStaff(
        name,
        username,
        password,
      );
      return right(staff);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStaff(String staffId) async {
    try {
      await remoteDataSource.deleteStaff(staffId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> checkUsername(String username) async {
    try {
      final exists = await remoteDataSource.checkUsername(username);
      return right(exists);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, StaffProfile>> updateStaffSalary({
    required String staffId,
    int? salary,
    String? salaryType,
    int? hourlyRate,
    int? minuteRate,
  }) async {
    try {
      final staff = await remoteDataSource.updateStaffSalary(
        staffId: staffId,
        salary: salary,
        salaryType: salaryType,
        hourlyRate: hourlyRate,
        minuteRate: minuteRate,
      );
      return right(staff);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}

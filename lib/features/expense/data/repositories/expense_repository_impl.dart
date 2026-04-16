import 'package:fpdart/fpdart.dart';
import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:flow_pos/features/expense/data/models/expense_category_model.dart';
import 'package:flow_pos/features/expense/data/models/expense_model.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_category.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_entity.dart';
import 'package:flow_pos/features/expense/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;

  ExpenseRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<ExpenseCategory>>> getCategories() async {
    try {
      final result = await _remoteDataSource.getCategories();
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, ExpenseCategory>> createCategory(ExpenseCategory category) async {
    try {
      final model = ExpenseCategoryModel(
        id: category.id,
        name: category.name,
        type: category.type,
      );
      final result = await _remoteDataSource.createCategory(model);
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryId) async {
    try {
      await _remoteDataSource.deleteCategory(categoryId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> createExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel(
        id: expense.id,
        amount: expense.amount,
        categoryId: expense.categoryId,
        categoryName: expense.categoryName,
        note: expense.note,
        type: expense.type,
        cashActionType: expense.cashActionType,
        staffId: expense.staffId,
        staffName: expense.staffName,
        shiftId: expense.shiftId,
        createdAt: expense.createdAt,
        isAdjustment: expense.isAdjustment,
      );
      final result = await _remoteDataSource.createExpense(model);
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? type,
    String? staffId,
    String? shiftId,
  }) async {
    try {
      final result = await _remoteDataSource.getExpenses(
        start: start,
        end: end,
        type: type,
        staffId: staffId,
        shiftId: shiftId,
      );
      return right(result);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}

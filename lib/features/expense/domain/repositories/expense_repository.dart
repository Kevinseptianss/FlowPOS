import 'package:fpdart/fpdart.dart';
import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_category.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_entity.dart';

abstract interface class ExpenseRepository {
  Future<Either<Failure, List<ExpenseCategory>>> getCategories();
  Future<Either<Failure, ExpenseCategory>> createCategory(ExpenseCategory category);
  Future<Either<Failure, void>> deleteCategory(String categoryId);

  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    DateTime? start,
    DateTime? end,
    String? type,
    String? staffId,
    String? shiftId,
  });
  Future<Either<Failure, ExpenseEntity>> createExpense(ExpenseEntity expense);
}

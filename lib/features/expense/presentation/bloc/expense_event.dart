part of 'expense_bloc.dart';

sealed class ExpenseEvent {}

final class GetExpensesEvent extends ExpenseEvent {
  final DateTime? start;
  final DateTime? end;
  final String? type;
  final String? staffId;
  final String? shiftId;

  GetExpensesEvent({this.start, this.end, this.type, this.staffId, this.shiftId});
}

final class CreateExpenseEvent extends ExpenseEvent {
  final ExpenseEntity expense;

  CreateExpenseEvent(this.expense);
}

final class GetExpenseCategoriesEvent extends ExpenseEvent {}

final class CreateExpenseCategoryEvent extends ExpenseEvent {
  final ExpenseCategory category;

  CreateExpenseCategoryEvent(this.category);
}

final class DeleteExpenseCategoryEvent extends ExpenseEvent {
  final String categoryId;

  DeleteExpenseCategoryEvent(this.categoryId);
}

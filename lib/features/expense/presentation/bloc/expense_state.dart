part of 'expense_bloc.dart';

sealed class ExpenseState {}

final class ExpenseInitial extends ExpenseState {}

final class ExpenseLoading extends ExpenseState {}

final class ExpenseFailure extends ExpenseState {
  final String message;

  ExpenseFailure(this.message);
}

final class ExpensesLoaded extends ExpenseState {
  final List<ExpenseEntity> expenses;

  ExpensesLoaded(this.expenses);
}

final class ExpenseCreated extends ExpenseState {
  final ExpenseEntity expense;

  ExpenseCreated(this.expense);
}

final class ExpenseCategoriesLoaded extends ExpenseState {
  final List<ExpenseCategory> categories;

  ExpenseCategoriesLoaded(this.categories);
}

final class ExpenseCategoryCreated extends ExpenseState {}

final class ExpenseCategoryDeleted extends ExpenseState {}

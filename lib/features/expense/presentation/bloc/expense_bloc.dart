import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_category.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_entity.dart';
import 'package:flow_pos/features/expense/domain/repositories/expense_repository.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc({
    required ExpenseRepository repository,
  })  : _repository = repository,
        super(ExpenseInitial()) {
    on<GetExpensesEvent>(_onGetExpenses);
    on<CreateExpenseEvent>(_onCreateExpense);
    on<GetExpenseCategoriesEvent>(_onGetCategories);
    on<CreateExpenseCategoryEvent>(_onCreateCategory);
    on<DeleteExpenseCategoryEvent>(_onDeleteCategory);
  }

  void _onGetExpenses(GetExpensesEvent event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await _repository.getExpenses(
      start: event.start,
      end: event.end,
      type: event.type,
      staffId: event.staffId,
      shiftId: event.shiftId,
    );
    result.fold(
      (failure) => emit(ExpenseFailure(failure.message)),
      (expenses) => emit(ExpensesLoaded(expenses)),
    );
  }

  void _onCreateExpense(CreateExpenseEvent event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await _repository.createExpense(event.expense);
    result.fold(
      (failure) => emit(ExpenseFailure(failure.message)),
      (expense) => emit(ExpenseCreated(expense)),
    );
  }

  void _onGetCategories(GetExpenseCategoriesEvent event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await _repository.getCategories();
    result.fold(
      (failure) => emit(ExpenseFailure(failure.message)),
      (categories) => emit(ExpenseCategoriesLoaded(categories)),
    );
  }

  void _onCreateCategory(CreateExpenseCategoryEvent event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await _repository.createCategory(event.category);
    result.fold(
      (failure) => emit(ExpenseFailure(failure.message)),
      (_) => emit(ExpenseCategoryCreated()),
    );
  }

  void _onDeleteCategory(DeleteExpenseCategoryEvent event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    final result = await _repository.deleteCategory(event.categoryId);
    result.fold(
      (failure) => emit(ExpenseFailure(failure.message)),
      (_) => emit(ExpenseCategoryDeleted()),
    );
  }
}

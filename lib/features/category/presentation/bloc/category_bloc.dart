import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/domain/usecases/get_all_categories.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetAllCategories _getAllCategories;

  CategoryBloc({required GetAllCategories getAllCategories})
    : _getAllCategories = getAllCategories,
      super(CategoryInitial()) {
    on<GetAllCategoriesEvent>(_onGetAllCategories);
  }

  void _onGetAllCategories(
    GetAllCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());

    final result = await _getAllCategories(NoParams());

    result.fold(
      (l) => emit(CategoryFailure(l.message)),
      (r) => emit(CategoryLoaded(r)),
    );
  }
}

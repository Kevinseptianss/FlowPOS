import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/domain/usecases/create_category.dart';
import 'package:flow_pos/features/category/domain/usecases/get_all_categories.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetAllCategories _getAllCategories;
  final CreateCategory _createCategory;

  CategoryBloc({
    required GetAllCategories getAllCategories,
    required CreateCategory createCategory,
  }) : _getAllCategories = getAllCategories,
       _createCategory = createCategory,
       super(CategoryInitial()) {
    on<GetAllCategoriesEvent>(_onGetAllCategories);
    on<CreateCategoryEvent>(_onCreateCategory);
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

  void _onCreateCategory(
    CreateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());

    final createResult = await _createCategory(
      CreateCategoryParams(name: event.name),
    );

    final createFailed = createResult.fold<bool>((_) => true, (_) => false);
    if (createFailed) {
      createResult.fold((l) => emit(CategoryFailure(l.message)), (_) {});
      return;
    }

    final getAllResult = await _getAllCategories(NoParams());

    getAllResult.fold(
      (l) => emit(CategoryFailure(l.message)),
      (r) => emit(CategoryLoaded(r)),
    );
  }
}

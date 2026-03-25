part of 'category_bloc.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object> get props => [];
}

final class GetAllCategoriesEvent extends CategoryEvent {}

final class CreateCategoryEvent extends CategoryEvent {
  final String name;

  const CreateCategoryEvent({required this.name});

  @override
  List<Object> get props => [name];
}

part of 'category_bloc.dart';

sealed class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object> get props => [];
}

final class CategoryInitial extends CategoryState {}

final class CategoryLoading extends CategoryState {}

final class CategoryLoaded extends CategoryState {
  final List<Category> categories;

  const CategoryLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

final class CategoryFailure extends CategoryState {
  final String message;

  const CategoryFailure(this.message);

  @override
  List<Object> get props => [message];
}

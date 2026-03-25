part of 'category_bloc.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object> get props => [];
}

final class GetAllCategoriesEvent extends CategoryEvent {}

final class StartCategoriesRealtimeEvent extends CategoryEvent {}

final class StopCategoriesRealtimeEvent extends CategoryEvent {}

final class CategoriesRealtimeUpdatedEvent extends CategoryEvent {
  final List<Category> categories;

  const CategoriesRealtimeUpdatedEvent(this.categories);

  @override
  List<Object> get props => [categories];
}

final class CategoriesRealtimeFailureEvent extends CategoryEvent {
  final String message;

  const CategoriesRealtimeFailureEvent(this.message);

  @override
  List<Object> get props => [message];
}

final class CreateCategoryEvent extends CategoryEvent {
  final String name;

  const CreateCategoryEvent({required this.name});

  @override
  List<Object> get props => [name];
}

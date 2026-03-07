part of 'list_category_bloc.dart';

abstract class ListCategoryState extends Equatable {
  const ListCategoryState();

  @override
  List<Object?> get props => [];
}

class ListCategoryInitial extends ListCategoryState {
  const ListCategoryInitial();
}

class ListCategoryLoading extends ListCategoryState {
  const ListCategoryLoading();
}

class ListCategoryLoaded extends ListCategoryState {
  final List<CategoryEntity> categories;

  const ListCategoryLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

class ListCategoryError extends ListCategoryState {
  final String message;

  const ListCategoryError({required this.message});

  @override
  List<Object?> get props => [message];
}


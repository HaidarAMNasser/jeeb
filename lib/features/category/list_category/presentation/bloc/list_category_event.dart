part of 'list_category_bloc.dart';

abstract class ListCategoryEvent extends Equatable {
  const ListCategoryEvent();

  @override
  List<Object> get props => [];
}

class GetCategoriesEvent extends ListCategoryEvent {
  const GetCategoriesEvent();
}


import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';
import 'package:jeeb_app/features/category/list_category/data/repositories/list_category_repository.dart';

part 'list_category_event.dart';
part 'list_category_state.dart';

class ListCategoryBloc extends Bloc<ListCategoryEvent, ListCategoryState> {
  final ListCategoryRepository _repository;

  ListCategoryBloc(this._repository) : super(const ListCategoryInitial()) {
    on<ListCategoryEvent>((event, emit) async {
      if (event is GetCategoriesEvent) {
        emit(const ListCategoryLoading());
        final result = await _repository.getCategories();
        result.fold(
          (failure) => emit(ListCategoryError(message: failure.message)),
          (categories) => emit(ListCategoryLoaded(categories: categories)),
        );
      }
    });
  }
}


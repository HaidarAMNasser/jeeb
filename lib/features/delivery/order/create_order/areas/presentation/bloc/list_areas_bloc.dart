import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/data/repositories/list_areas_repository.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/domain/entities/area_entity.dart';

part 'list_areas_event.dart';
part 'list_areas_state.dart';

class ListAreasBloc extends Bloc<ListAreasEvent, ListAreasState> {
  final ListAreasRepository _repository;
  static const int _pageSize = 20;

  ListAreasBloc(this._repository) : super(const ListAreasInitial()) {
    on<ListAreasEvent>((event, emit) async {
      if (event is GetAreasEvent) {
        if (event.loadMore) {
          final currentState = state;
          if (currentState is ListAreasLoaded) {
            final searchQuery = event.search ?? currentState.search;

            emit(
              ListAreasLoadingMore(
                areas: currentState.areas,
                currentPage: currentState.currentPage,
                search: searchQuery,
              ),
            );

            final nextPage = currentState.currentPage + 1;

            final result = await _repository.getAreas(
              page: nextPage,
              limit: _pageSize,
              search: searchQuery,
            );

            result.fold(
              (failure) => emit(ListAreasError(message: failure.message)),
              (paginatedAreas) {
                final updatedAreas = [
                  ...currentState.areas,
                  ...paginatedAreas.areas,
                ];
                emit(
                  ListAreasLoaded(
                    areas: updatedAreas,
                    hasMore: paginatedAreas.pagination?.hasNextPage ?? false,
                    currentPage: nextPage,
                    search: searchQuery,
                  ),
                );
              },
            );
          }
        } else {
          emit(const ListAreasLoading());

          final result = await _repository.getAreas(
            page: 1,
            limit: _pageSize,
            search: event.search,
          );

          result.fold(
            (failure) => emit(ListAreasError(message: failure.message)),
            (paginatedAreas) => emit(
              ListAreasLoaded(
                areas: paginatedAreas.areas,
                hasMore: paginatedAreas.pagination?.hasNextPage ?? false,
                currentPage: 1,
                search: event.search,
              ),
            ),
          );
        }
      }
    });
  }
}

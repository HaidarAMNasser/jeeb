part of 'list_areas_bloc.dart';

abstract class ListAreasEvent extends Equatable {
  const ListAreasEvent();

  @override
  List<Object> get props => [];
}

class GetAreasEvent extends ListAreasEvent {
  final bool loadMore;
  final String? search;

  const GetAreasEvent({
    this.loadMore = false,
    this.search,
  });

  @override
  List<Object> get props => [loadMore, search ?? ''];
}

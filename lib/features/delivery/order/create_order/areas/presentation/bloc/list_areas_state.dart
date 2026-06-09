part of 'list_areas_bloc.dart';

abstract class ListAreasState extends Equatable {
  const ListAreasState();

  @override
  List<Object?> get props => [];
}

class ListAreasInitial extends ListAreasState {
  const ListAreasInitial();
}

class ListAreasLoading extends ListAreasState {
  const ListAreasLoading();
}

class ListAreasLoaded extends ListAreasState {
  final List<AreaEntity> areas;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final String? search;

  const ListAreasLoaded({
    required this.areas,
    this.hasMore = true,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.search,
  });

  ListAreasLoaded copyWith({
    List<AreaEntity>? areas,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    String? search,
  }) {
    return ListAreasLoaded(
      areas: areas ?? this.areas,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props =>
      [areas, hasMore, currentPage, isLoadingMore, search];
}

class ListAreasLoadingMore extends ListAreasState {
  final List<AreaEntity> areas;
  final int currentPage;
  final String? search;

  const ListAreasLoadingMore({
    required this.areas,
    required this.currentPage,
    this.search,
  });

  @override
  List<Object?> get props => [areas, currentPage, search];
}

class ListAreasError extends ListAreasState {
  final String message;

  const ListAreasError({required this.message});

  @override
  List<Object?> get props => [message];
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/domain/entities/area_entity.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/presentation/bloc/list_areas_bloc.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/presentation/widgets/area_option_tile.dart';

class AreaSelectionList extends StatefulWidget {
  final ListAreasBloc bloc;
  final ValueChanged<AreaEntity> onAreaSelected;

  const AreaSelectionList({
    super.key,
    required this.bloc,
    required this.onAreaSelected,
  });

  @override
  State<AreaSelectionList> createState() => _AreaSelectionListState();
}

class _AreaSelectionListState extends State<AreaSelectionList> {
  late final ScrollController _scrollController;
  String? _selectedAreaId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels < position.maxScrollExtent * 0.8) return;

    final state = widget.bloc.state;
    if (state is ListAreasLoaded && state.hasMore) {
      widget.bloc.add(const GetAreasEvent(loadMore: true));
    }
  }

  void _onAreaTap(AreaEntity area) {
    setState(() => _selectedAreaId = area.id);
    widget.onAreaSelected(area);
  }

  Widget _buildList(ListAreasState state) {
    final areas = state is ListAreasLoaded
        ? state.areas
        : (state as ListAreasLoadingMore).areas;
    final isLoadingMore = state is ListAreasLoadingMore;

    return ListView.separated(
      controller: _scrollController,
      itemCount: areas.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: AppHeight.s12),
      itemBuilder: (context, index) {
        if (index >= areas.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CustomCircleIndicator(),
          );
        }

        final area = areas[index];
        return AreaOptionTile(
          area: area,
          isSelected: _selectedAreaId == area.id,
          onTap: () => _onAreaTap(area),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocStateHandler<ListAreasBloc, ListAreasState>(
      bloc: widget.bloc,
      isLoading: (state) => state is ListAreasLoading,
      isError: (state) => state is ListAreasError,
      getErrorMessage: (state) =>
          state is ListAreasError ? state.message : '',
      isSuccess: (state) =>
          state is ListAreasLoaded || state is ListAreasLoadingMore,
      isEmpty: (state) =>
          (state is ListAreasLoaded || state is ListAreasLoadingMore) &&
          (state is ListAreasLoaded
              ? state.areas.isEmpty
              : (state as ListAreasLoadingMore).areas.isEmpty),
      emptyMessage: AppTranslation.noAreasAvailable,
      getRetryCallback: (_) => () => widget.bloc.add(const GetAreasEvent()),
      successBuilder: (_, state) => _buildList(state),
    );
  }
}

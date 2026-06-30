import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_paginated_dropdown.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/domain/entities/area_entity.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/presentation/bloc/list_areas_bloc.dart';

/// Delivery area picker for checkout — same [CustomPaginatedDropdown] as country/city.
class BasketConfirmationAreaDropdown extends StatefulWidget {
  const BasketConfirmationAreaDropdown({
    super.key,
    required this.selectedArea,
    required this.onAreaChanged,
  });

  final AreaEntity? selectedArea;
  final ValueChanged<AreaEntity?> onAreaChanged;

  @override
  State<BasketConfirmationAreaDropdown> createState() =>
      _BasketConfirmationAreaDropdownState();
}

class _BasketConfirmationAreaDropdownState
    extends State<BasketConfirmationAreaDropdown> {
  @override
  void initState() {
    super.initState();
    context.read<ListAreasBloc>().add(const GetAreasEvent());
  }

  String _areaDisplayText(AreaEntity area) {
    final price = (area.displayPrice / 100).toStringAsFixed(2);
    return '${area.name} — SYP $price';
  }

  void _refreshAreas() {
    context.read<ListAreasBloc>().add(const GetAreasEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListAreasBloc, ListAreasState>(
      builder: (context, state) {
        var areas = <AreaEntity>[];
        var isLoading = false;
        var isLoadingMore = false;
        var hasMore = true;
        var isError = false;
        String? errorMessage;

        if (state is ListAreasLoading) {
          isLoading = true;
        } else if (state is ListAreasError) {
          isError = true;
          errorMessage = state.message;
        } else if (state is ListAreasLoaded) {
          areas = state.areas;
          hasMore = state.hasMore;
        } else if (state is ListAreasLoadingMore) {
          areas = state.areas;
          isLoadingMore = true;
        }

        AreaEntity? selected = widget.selectedArea;
        if (selected != null) {
          for (final a in areas) {
            if (a.id == selected!.id) {
              selected = a;
              break;
            }
          }
        }

        return CustomPaginatedDropdown<AreaEntity>(
          title: AppTranslation.selectArea,
          hintText: areas.isEmpty
              ? AppTranslation.noAreasAvailable
              : AppTranslation.selectArea,
          items: areas,
          selectedItem: selected,
          displayText: _areaDisplayText,
          onChanged: widget.onAreaChanged,
          onLoadMore: () {
            if (hasMore && !isLoadingMore) {
              context
                  .read<ListAreasBloc>()
                  .add(const GetAreasEvent(loadMore: true));
            }
          },
          isLoading: isLoading,
          isLoadingMore: isLoadingMore,
          hasMoreData: hasMore,
          isError: isError,
          errorMessage: errorMessage,
          isRequired: true,
          onRefresh: _refreshAreas,
          refreshTooltip: AppTranslation.retry,
          itemBuilder: (context, area, isSelected) {
            final hasDesc =
                area.description != null && area.description!.trim().isNotEmpty;
            final price = (area.displayPrice / 100).toStringAsFixed(2);

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p16,
                vertical: AppHeight.s12,
              ),
              color: isSelected
                  ? ColorManager.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: area.name,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s14,
                            color: isSelected
                                ? ColorManager.primary
                                : ColorManager.productNameColor,
                          ),
                        ),
                        if (hasDesc) ...[
                          SizedBox(height: AppHeight.s4),
                          CustomText(
                            text: area.description!,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s12,
                              color: ColorManager.descriptionColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: AppPadding.p8),
                  CustomText(
                    text: 'SYP $price',
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s13,
                      color: ColorManager.primary,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(width: AppPadding.p8),
                    Icon(
                      Icons.check,
                      size: 20,
                      color: ColorManager.primary,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

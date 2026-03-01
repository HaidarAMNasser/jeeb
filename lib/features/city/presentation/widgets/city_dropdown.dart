import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';
import 'package:jeeb_app/features/city/presentation/bloc/city_bloc.dart';

class CityDropdown extends StatefulWidget {
  final int? selectedCityId;
  final ValueChanged<int?> onChanged;

  const CityDropdown({
    super.key,
    required this.selectedCityId,
    required this.onChanged,
  });

  @override
  State<CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<CityDropdown> {
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_scrollController.position.outOfRange) {
      final state = context.read<CityBloc>().state;
      if (state is CityLoaded && !state.isLoadingMore && !state.hasReachedMax) {
        context.read<CityBloc>().add(const LoadMoreCities());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';

    return BlocBuilder<CityBloc, CityState>(
      builder: (context, state) {
        if (state is CityLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                text: AppTranslation.selectCity,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.defaultWhite,
                ),
              ),
              SizedBox(height: AppHeight.s8),
              Container(
                height: AppHeight.s56,
                decoration: BoxDecoration(
                  color: ColorManager.defaultWhite,
                  borderRadius: BorderRadius.circular(AppRadius.r18),
                  border: Border.all(color: ColorManager.borderColor),
                ),
                child: const Center(child: CustomCircleIndicator()),
              ),
            ],
          );
        }

        if (state is CityError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                text: AppTranslation.selectCity,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.defaultWhite,
                ),
              ),
              SizedBox(height: AppHeight.s8),
              Container(
                height: AppHeight.s56,
                decoration: BoxDecoration(
                  color: ColorManager.defaultWhite,
                  borderRadius: BorderRadius.circular(AppRadius.r18),
                  border: Border.all(color: ColorManager.borderColor),
                ),
                child: Center(
                  child: CustomText(
                    text: state.message,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.warning,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (state is CityLoaded) {
          final cities = state.cities;

          if (cities.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  text: AppTranslation.selectCity,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: ColorManager.defaultWhite,
                  ),
                ),
                SizedBox(height: AppHeight.s8),
                Container(
                  height: AppHeight.s56,
                  decoration: BoxDecoration(
                    color: ColorManager.defaultWhite,
                    borderRadius: BorderRadius.circular(AppRadius.r18),
                    border: Border.all(color: ColorManager.borderColor),
                  ),
                  child: Center(
                    child: CustomText(
                      text: AppTranslation.noCitiesAvailable,
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s14,
                        color: ColorManager.descriptionColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          CityEntity? selectedCity;
          if (widget.selectedCityId != null) {
            try {
              selectedCity = cities.firstWhere(
                (c) => c.id == widget.selectedCityId,
              );
            } catch (e) {
              selectedCity = null;
            }
          }
          final displayText = selectedCity != null
              ? (isRTL ? selectedCity.name.ar : selectedCity.name.en)
              : AppTranslation.selectCity;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                text: AppTranslation.selectCity,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.defaultWhite,
                ),
              ),
              SizedBox(height: AppHeight.s8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  height: AppHeight.s56,
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                  decoration: BoxDecoration(
                    color: ColorManager.defaultWhite,
                    borderRadius: _isExpanded
                        ? BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.r18),
                            topRight: Radius.circular(AppRadius.r18),
                          )
                        : BorderRadius.circular(AppRadius.r18),
                    border: Border.all(color: ColorManager.borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: displayText,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s14,
                            color: widget.selectedCityId != null
                                ? ColorManager.productNameColor
                                : ColorManager.descriptionColor,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: ColorManager.descriptionColor,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded && cities.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: ColorManager.defaultWhite,
                    border: Border(
                      left: BorderSide(color: ColorManager.borderColor),
                      right: BorderSide(color: ColorManager.borderColor),
                      bottom: BorderSide(color: ColorManager.borderColor),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppRadius.r18),
                      bottomRight: Radius.circular(AppRadius.r18),
                    ),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: cities.length + (state.hasReachedMax ? 0 : 1),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index == cities.length) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: state.isLoadingMore
                                ? const CustomCircleIndicator()
                                : const SizedBox.shrink(),
                          ),
                        );
                      }

                      final city = cities[index];
                      final cityName = isRTL ? city.name.ar : city.name.en;
                      final isSelected = city.id == widget.selectedCityId;

                      return InkWell(
                        onTap: () {
                          widget.onChanged(city.id);
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppPadding.p16,
                            vertical: AppHeight.s12,
                          ),
                          color: isSelected
                              ? ColorManager.primary.withOpacity(0.1)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  text: cityName,
                                  textStyle: getRegularStyle(
                                    fontSize: AppFontSize.s14,
                                    color: isSelected
                                        ? ColorManager.primary
                                        : ColorManager.productNameColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 20,
                                  color: ColorManager.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              text: AppTranslation.selectCity,
              textStyle: getSemiBoldStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.defaultWhite,
              ),
            ),
            SizedBox(height: AppHeight.s8),
            Container(
              height: AppHeight.s56,
              decoration: BoxDecoration(
                color: ColorManager.defaultWhite,
                borderRadius: BorderRadius.circular(AppRadius.r18),
                border: Border.all(color: ColorManager.borderColor),
              ),
              child: Center(
                child: CustomText(
                  text: AppTranslation.pleaseSelectCountryFirst,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.descriptionColor,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

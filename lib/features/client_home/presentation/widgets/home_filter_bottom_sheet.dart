import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_dropdown.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_event.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';

import 'package:jeeb_app/features/client_home/presentation/widgets/category_paginated_dropdown.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/rating_selector.dart';

class HomeFilterBottomSheet extends StatefulWidget {
  const HomeFilterBottomSheet({super.key});

  @override
  State<HomeFilterBottomSheet> createState() => _HomeFilterBottomSheetState();
}

class _HomeFilterBottomSheetState extends State<HomeFilterBottomSheet> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  String? _selectedCategoryId;
  int? _minRating;

  @override
  void initState() {
    super.initState();
    final state = context.read<ClientHomeBloc>().state;
    _minPriceController = TextEditingController(
      text: state.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: state.maxPrice?.toString() ?? '',
    );
    _selectedCategoryId = state.selectedCategoryId;
    _minRating = state.minRating;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientHomeBloc, ClientHomeState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(AppPadding.p16),
          decoration: BoxDecoration(
            color: ColorManager.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.r24),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: AppTranslation.filters,
                      textStyle: getBoldStyle(
                        fontSize: AppFontSize.s20,
                        color: ColorManager.titlesColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _minPriceController.clear();
                          _maxPriceController.clear();
                          _selectedCategoryId = null;
                          _minRating = null;
                        });
                      },
                      child: CustomText(
                        text: AppTranslation.reset,
                        textStyle: getSemiBoldStyle(
                          fontSize: AppFontSize.s14,
                          color: ColorManager.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppHeight.s24),
                CategoryPaginatedDropdown(
                  title: AppTranslation.selectCategory,
                  initialValue: _selectedCategoryId,
                  hintText: AppTranslation.allCategories,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
                SizedBox(height: AppHeight.s20),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        title: AppTranslation.minPrice,
                        hintText: AppTranslation.minPriceHint,
                        controller: _minPriceController,
                        keyboardType: TextInputType.number,
                        filledColor: ColorManager.surface,
                        textColor: ColorManager.productNameColor,
                      ),
                    ),
                    SizedBox(width: AppPadding.p16),
                    Expanded(
                      child: CustomTextField(
                        title: AppTranslation.maxPrice,
                        hintText: AppTranslation.maxPriceHint,
                        controller: _maxPriceController,
                        keyboardType: TextInputType.number,
                        filledColor: ColorManager.surface,
                        textColor: ColorManager.productNameColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppHeight.s20),
                CustomText(
                  text: AppTranslation.minRating,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: ColorManager.titlesColor,
                  ),
                ),
                SizedBox(height: AppHeight.s8),
                RatingSelector(
                  selectedRating: _minRating,
                  onRatingSelected: (rating) {
                    setState(() {
                      _minRating = rating;
                    });
                  },
                ),
                SizedBox(height: AppHeight.s32),
                CustomButton(
                  text: AppTranslation.apply,
                  onPressed: () {
                    final minPrice = double.tryParse(_minPriceController.text);
                    final maxPrice = double.tryParse(_maxPriceController.text);
                    context.read<ClientHomeBloc>().add(
                      ApplyFiltersEvent(
                        minPrice: minPrice,
                        maxPrice: maxPrice,
                        minRating: _minRating,
                        categoryId: _selectedCategoryId,
                      ),
                    );
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: AppHeight.s16),
              ],
            ),
          ),
        );
      },
    );
  }
}

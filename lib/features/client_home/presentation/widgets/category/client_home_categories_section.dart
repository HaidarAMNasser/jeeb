import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_event.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/category/category_chip.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/category/categories_shimmer.dart';

/// Horizontal scrollable circular category chips. Tapping one refreshes products by category.
class ClientHomeCategoriesSection extends StatelessWidget {
  const ClientHomeCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: AppTranslation.categories,
          textStyle: getBoldStyle(
            fontSize: AppFontSize.s18,
            color: ColorManager.titlesColor,
          ),
        ),
        SizedBox(height: AppHeight.s12),
        BlocBuilder<ClientHomeBloc, ClientHomeState>(
          buildWhen: (a, b) =>
              a.isCategoriesLoading != b.isCategoriesLoading ||
              a.categories != b.categories ||
              a.selectedCategoryId != b.selectedCategoryId,
          builder: (context, state) {
            if (state.isCategoriesLoading) {
              return const CategoriesShimmer();
            }

            final categories = state.categories;
            final selectedId = state.selectedCategoryId;

            if (categories.isEmpty) {
              return SizedBox(
                height: AppHeight.s78,
                child: Center(
                  child: CustomText(
                    text: AppTranslation.noCategoriesFound,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: AppHeight.s100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => SizedBox(width: AppPadding.p12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CategoryChip(
                      label: AppTranslation.allCategories,
                      isSelected: selectedId == null,
                      onTap: () => context.read<ClientHomeBloc>().add(
                        const SelectCategoryEvent(null),
                      ),
                    );
                  }
                  final category = categories[index - 1];
                  return CategoryChip(
                    label: category.name,
                    imageUrl: category.imageUrl,
                    isSelected: selectedId == category.id,
                    onTap: () => context.read<ClientHomeBloc>().add(
                      SelectCategoryEvent(category.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

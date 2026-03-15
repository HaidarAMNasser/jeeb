import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_cubit.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_state.dart';

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
        BlocBuilder<ClientHomeCubit, ClientHomeState>(
          buildWhen: (a, b) =>
              a.categories != b.categories ||
              a.selectedCategoryId != b.selectedCategoryId,
          builder: (context, state) {
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
                    return _CategoryChip(
                      label: 'All',
                      isSelected: selectedId == null,
                      onTap: () =>
                          context.read<ClientHomeCubit>().selectCategory(null),
                    );
                  }
                  final category = categories[index - 1];
                  return _CategoryChip(
                    label: category.name,
                    imageUrl: category.imageUrl,
                    isSelected: selectedId == category.id,
                    onTap: () => context.read<ClientHomeCubit>().selectCategory(
                      category.id,
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppHeight.s66,
            height: AppHeight.s66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? ColorManager.primary : ColorManager.surface,
              border: Border.all(
                color: isSelected
                    ? ColorManager.primary
                    : ColorManager.borderColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      width: AppHeight.s66,
                      height: AppHeight.s66,
                      placeholder: (_, __) => Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorManager.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _buildLabelContent(),
                    )
                  : _buildLabelContent(),
            ),
          ),
          SizedBox(height: AppHeight.s5),
          CustomText(
            text: label.length > 10 ? '${label.substring(0, 9)}…' : label,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s12,
              color: ColorManager.textColor,
            ),
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLabelContent() {
    return Center(
      child: CustomText(
        text: label.length > 8 ? '${label.substring(0, 7)}…' : label,
        textStyle: getSemiBoldStyle(
          fontSize: AppFontSize.s12,
          color: isSelected
              ? ColorManager.defaultWhite
              : ColorManager.productNameColor,
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
      ),
    );
  }
}

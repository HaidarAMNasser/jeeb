import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class RatingSelector extends StatelessWidget {
  final int? selectedRating;
  final ValueChanged<int?> onRatingSelected;

  const RatingSelector({
    super.key,
    this.selectedRating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = selectedRating == rating;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: InkWell(
            onTap: () => onRatingSelected(isSelected ? null : rating),
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p12,
                vertical: AppHeight.s10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? ColorManager.primary : ColorManager.surface,
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(
                  color: isSelected ? ColorManager.primary : ColorManager.borderColor,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: rating.toString(),
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: isSelected ? ColorManager.defaultWhite : ColorManager.productNameColor,
                    ),
                  ),
                  SizedBox(width: AppPadding.p4),
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: isSelected ? ColorManager.defaultWhite : Colors.amber,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

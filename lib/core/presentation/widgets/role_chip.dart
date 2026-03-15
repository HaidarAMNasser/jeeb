import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppPadding.p12,
          vertical: AppHeight.s8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorManager.primary
              : ColorManager.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        child: CustomText(
          text: label,
          textStyle: getMediumStyle(
            fontSize: AppFontSize.s14,
            color: isSelected
                ? ColorManager.defaultWhite
                : ColorManager.primary,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

enum LocationChoice { current, map }

class LocationChoiceDialog extends StatelessWidget {
  const LocationChoiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
      child: Container(
        padding: EdgeInsets.all(AppPadding.p24),
        decoration: BoxDecoration(
          color: ColorManager.background,
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              text: AppTranslation.chooseLocationOnMap,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s10),
            CustomText(
              text: AppTranslation.pleaseSelectCountryOrLocation,
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            _LocationOption(
              icon: Icons.my_location_rounded,
              title: AppTranslation.useMyLocation,
              onTap: () => Navigator.of(context).pop(LocationChoice.current),
            ),
            SizedBox(height: AppHeight.s12),
            _LocationOption(
              icon: Icons.map_rounded,
              title: AppTranslation.chooseLocationOnMap,
              onTap: () => Navigator.of(context).pop(LocationChoice.map),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LocationOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Container(
        padding: EdgeInsets.all(AppPadding.p16),
        decoration: BoxDecoration(
          color: ColorManager.background,
          border: Border.all(color: ColorManager.borderColor),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorManager.primary, size: AppSize.s22),
            SizedBox(width: AppWidth.s10),
            Expanded(
              child: CustomText(
                text: title,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.titlesColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: AppSize.s16,
              color: ColorManager.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

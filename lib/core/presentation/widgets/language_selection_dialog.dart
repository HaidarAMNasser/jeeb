import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

class LanguageSelectionDialog extends StatelessWidget {
  final String? currentLanguage;

  const LanguageSelectionDialog({
    super.key,
    this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = currentLanguage ?? context.locale.languageCode;

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
            // Title
            CustomText(
              text: AppTranslation.selectLanguage,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            // English Option
            _LanguageOption(
              languageCode: 'en',
              languageName: 'English',
              isSelected: selectedLanguage == 'en',
              onTap: () => _selectLanguage(context, 'en'),
            ),
            SizedBox(height: AppHeight.s16),
            // Arabic Option
            _LanguageOption(
              languageCode: 'ar',
              languageName: 'العربية',
              isSelected: selectedLanguage == 'ar',
              onTap: () => _selectLanguage(context, 'ar'),
            ),
            SizedBox(height: AppHeight.s24),
            // Close Button
            CustomButton(
              text: AppTranslation.close,
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
              color: ColorManager.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, String languageCode) {
    Navigator.of(context).pop(languageCode);
  }
}

class _LanguageOption extends StatelessWidget {
  final String languageCode;
  final String languageName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.languageCode,
    required this.languageName,
    required this.isSelected,
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
          color: isSelected
              ? ColorManager.primary.withOpacity(0.1)
              : ColorManager.background,
          border: Border.all(
            color: isSelected
                ? ColorManager.primary
                : ColorManager.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            // Language Name
            Expanded(
              child: CustomText(
                text: languageName,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s18,
                  color: isSelected
                      ? ColorManager.primary
                      : ColorManager.titlesColor,
                ),
              ),
            ),
            // Check Icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorManager.primary,
                size: AppSize.s24,
              ),
          ],
        ),
      ),
    );
  }
}


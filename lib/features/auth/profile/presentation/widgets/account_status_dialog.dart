import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart' show getBoldStyle, getSemiBoldStyle;
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Shows a dialog to choose account status (Active / Inactive).
/// Returns [true] for active, [false] for inactive, [null] if closed without choosing.
Future<bool?> showAccountStatusDialog(BuildContext context,
    {required bool isActive}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AccountStatusDialog(isActive: isActive),
  );
}

class AccountStatusDialog extends StatelessWidget {
  const AccountStatusDialog({
    super.key,
    required this.isActive,
  });

  final bool isActive;

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
              text: AppTranslation.accountStatus,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            AccountStatusOption(
              label: AppTranslation.accountActive,
              isSelected: isActive,
              onTap: () => Navigator.of(context).pop(true),
            ),
            SizedBox(height: AppHeight.s16),
            AccountStatusOption(
              label: AppTranslation.accountInactive,
              isSelected: !isActive,
              onTap: () => Navigator.of(context).pop(false),
            ),
            SizedBox(height: AppHeight.s24),
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
}

class AccountStatusOption extends StatelessWidget {
  const AccountStatusOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

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
            Expanded(
              child: CustomText(
                text: label,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s18,
                  color: isSelected
                      ? ColorManager.primary
                      : ColorManager.titlesColor,
                ),
              ),
            ),
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

import 'package:flutter/material.dart';

import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Shows a delete-account confirmation dialog matching the logout dialog UI.
/// Returns [true] if user confirms deletion, [null] if cancelled.
Future<bool?> showDeleteAccountDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const DeleteAccountDialog(),
  );
}

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

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
              text: AppTranslation.deleteAccount,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            CustomText(
              text: AppTranslation.areYouSureDeleteAccount,
              textStyle: getMediumStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            CustomButton(
              text: AppTranslation.cancel,
              onPressed: () => Navigator.of(context).pop(false),
              isOutlined: true,
              color: ColorManager.primary,
            ),
            SizedBox(height: AppHeight.s16),
            CustomButton(
              text: AppTranslation.deleteAccount,
              onPressed: () => Navigator.of(context).pop(true),
              color: ColorManager.errorColor,
            ),
          ],
        ),
      ),
    );
  }
}

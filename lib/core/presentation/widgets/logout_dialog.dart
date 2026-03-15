import 'package:flutter/material.dart';

import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';


/// Shows a logout confirmation dialog matching the language selection dialog UI.
/// Returns [true] if user confirms logout, [null] if cancelled.
Future<bool?> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const LogoutDialog(),
  );
}

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

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
            // Title
            CustomText(
              text: AppTranslation.logout,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            // Message
            CustomText(
              text: AppTranslation.areYouSureLogout,
              textStyle: getMediumStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            // Cancel Button
            CustomButton(
              text: AppTranslation.cancel,
              onPressed: () => Navigator.of(context).pop(false),
              isOutlined: true,
              color: ColorManager.primary,
            ),
            SizedBox(height: AppHeight.s16),
            // Logout Button
            CustomButton(
              text: AppTranslation.logout,
              onPressed: () => Navigator.of(context).pop(true),
              color: ColorManager.primary,
            ),
          ],
        ),
      ),
    );
  }
}


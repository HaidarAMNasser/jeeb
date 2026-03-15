import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Reusable confirmation dialog matching OTP / language selection dialog UI.
///
/// Usage:
/// ```dart
/// ConfirmationDialog.show(
///   context: context,
///   title: AppTranslation.areYouSureDeleteOffer,
///   onConfirm: () { ... },
/// );
/// ```
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final VoidCallback onConfirm;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.onConfirm,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
  });

  static void show({
    required BuildContext context,
    required String title,
    required VoidCallback onConfirm,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        onConfirm: onConfirm,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
      ),
    );
  }

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
              text: title,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            CustomButton(
              text: cancelText ?? AppTranslation.cancel,
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
              color: ColorManager.primary,
            ),
            SizedBox(height: AppHeight.s16),
            CustomButton(
              text: confirmText ?? AppTranslation.confirm,
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              color: confirmColor ?? ColorManager.primary,
            ),
          ],
        ),
      ),
    );
  }
}

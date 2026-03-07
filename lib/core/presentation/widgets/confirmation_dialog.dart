import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';

/// A reusable confirmation dialog widget
///
/// Usage:
/// ```dart
/// ConfirmationDialog.show(
///   context: context,
///   title: AppTranslation.deleteProduct,
///   onConfirm: () {
///     // Handle confirmation
///   },
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

  /// Static method to show the confirmation dialog
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
    return AlertDialog(
      backgroundColor: ColorManager.surface,
      title: Text(
        title,
        style: getMediumStyle(fontSize: AppFontSize.s20, color: ColorManager.textDarkColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            cancelText ?? AppTranslation.cancel,
            style: TextStyle(color: ColorManager.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: TextButton.styleFrom(
            foregroundColor: confirmColor ?? Colors.red,
          ),
          child: Text(confirmText ?? AppTranslation.confirm),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';


/// Product details options dialog matching the app's language/confirmation dialog UI.
/// Shows Edit, Confirm (if admin), and Delete as tappable options.
class ProductDetailsOptionsDialog extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const ProductDetailsOptionsDialog({
    super.key,
    required this.isAdmin,
    required this.onEdit,
    required this.onConfirm,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isAdmin,
    required VoidCallback onEdit,
    required VoidCallback onConfirm,
    required VoidCallback onDelete,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ProductDetailsOptionsDialog(
        isAdmin: isAdmin,
        onEdit: onEdit,
        onConfirm: onConfirm,
        onDelete: onDelete,
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
              text: AppTranslation.options,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            _OptionTile(
              label: AppTranslation.editProduct,
              onTap: () {
                Navigator.of(context).pop();
                onEdit();
              },
            ),
            if (isAdmin) ...[
              SizedBox(height: AppHeight.s16),
              _OptionTile(
                label: AppTranslation.confirmProduct,
                onTap: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
              ),
            ],
            SizedBox(height: AppHeight.s16),
            _OptionTile(
              label: AppTranslation.deleteProduct,
              isDestructive: true,
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
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

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? ColorManager.primary : ColorManager.titlesColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Container(
        padding: EdgeInsets.all(AppPadding.p16),
        decoration: BoxDecoration(
          color: ColorManager.background,
          border: Border.all(
            color: isDestructive ? ColorManager.primary : ColorManager.borderColor,
            width: 1,
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
                  color: color,
                ),
              ),
            ),
            Icon(
              isDestructive ? Icons.delete_outline : Icons.arrow_forward_ios,
              size: AppSize.s18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

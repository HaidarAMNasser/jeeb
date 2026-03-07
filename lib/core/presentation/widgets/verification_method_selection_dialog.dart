import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

/// Dialog to choose how to verify account: Email OTP or WhatsApp OTP.
/// Returns 'EMAIL' or 'WHATSAPP' when an option is selected.
class VerificationMethodSelectionDialog extends StatelessWidget {
  const VerificationMethodSelectionDialog({super.key});

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
              text: AppTranslation.verifyAccountMethodTitle,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            _VerificationOption(
              label: AppTranslation.verifyEmailOtp,
              value: 'EMAIL',
              icon: Icons.email_outlined,
              onTap: () => Navigator.of(context).pop('EMAIL'),
            ),
            SizedBox(height: AppHeight.s16),
            _VerificationOption(
              label: AppTranslation.verifyWhatsAppOtp,
              value: 'WHATSAPP',
              icon: Icons.chat_bubble_outline,
              onTap: () => Navigator.of(context).pop('WHATSAPP'),
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

class _VerificationOption extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _VerificationOption({
    required this.label,
    required this.value,
    required this.icon,
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
          border: Border.all(color: ColorManager.borderColor, width: 1),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorManager.primary, size: AppSize.s24),
            SizedBox(width: AppWidth.s12),
            Expanded(
              child: CustomText(
                text: label,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.titlesColor,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: AppSize.s16,
              color: ColorManager.textColor,
            ),
          ],
        ),
      ),
    );
  }
}

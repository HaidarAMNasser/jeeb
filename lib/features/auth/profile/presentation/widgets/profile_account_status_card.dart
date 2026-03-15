import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';

/// Displays account active status for merchants and allows activating/deactivating.
class ProfileAccountStatusCard extends StatelessWidget {
  const ProfileAccountStatusCard({
    super.key,
    required this.user,
    required this.onActiveChanged,
  });

  final UserEntity user;
  final void Function(bool isActive) onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = user.isActive ?? true;

    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: ColorManager.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.remove_circle_outline,
                size: 22,
                color: isActive ? ColorManager.primary : ColorManager.descriptionColor,
              ),
              SizedBox(width: AppPadding.p8),
              CustomText(
                text: AppTranslation.accountStatus,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.productNameColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppHeight.s12),
          CustomText(
            text: isActive
                ? AppTranslation.accountActive
                : AppTranslation.accountInactive,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: isActive
                  ? ColorManager.primary
                  : ColorManager.descriptionColor,
            ),
          ),
          SizedBox(height: AppHeight.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: isActive
                    ? AppTranslation.deactivateAccount
                    : AppTranslation.activateAccount,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.productNameColor,
                ),
              ),
              Switch.adaptive(
                value: isActive,
                onChanged: (value) => onActiveChanged(value),
                activeColor: ColorManager.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

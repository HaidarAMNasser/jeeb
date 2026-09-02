import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_checkbox.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';

class ProfileForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final UserEntity user;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final VoidCallback onUpdate;
  final bool isLoading;
  final VoidCallback onChangeLanguage;
  final bool isMerchant;
  final VoidCallback onUpdateLocation;
  final ValueChanged<bool> onAccountStatusChanged;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;

  const ProfileForm({
    super.key,
    required this.formKey,
    required this.user,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.addressController,
    required this.onUpdate,
    required this.isLoading,
    required this.onChangeLanguage,
    required this.isMerchant,
    required this.onUpdateLocation,
    required this.onAccountStatusChanged,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        spacing: AppSize.s24.h,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMerchant)
            CustomCheckbox(
              value: user.isActive ?? true,
              onChanged: (value) {
                if (value != null) {
                  onAccountStatusChanged(value);
                }
              },
              label: AppTranslation.accountStatus,
            ),
          CustomTextField(
            title: AppTranslation.firstName,
            hintText: AppTranslation.firstName,
            controller: firstNameController,
          ),
          CustomTextField(
            title: AppTranslation.lastName,
            hintText: AppTranslation.lastName,
            controller: lastNameController,
          ),
          CustomTextField(
            title: AppTranslation.phone,
            hintText: AppTranslation.enterPhone,
            controller: phoneController,
          ),
          CustomTextField(
            title: AppTranslation.address,
            hintText: AppTranslation.enterAddress,
            controller: addressController,
          ),
          InkWell(
            onTap: onChangeLanguage,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppPadding.p8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language, size: 20, color: ColorManager.primary),
                  SizedBox(width: AppWidth.s8),
                  CustomText(
                    text: AppTranslation.changeLanguage,
                    textStyle: getMediumStyle(
                      color: ColorManager.primary,
                      fontSize: AppFontSize.s15,
                    ),
                  ),
                  SizedBox(width: AppWidth.s8),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onUpdateLocation,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppPadding.p8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: ColorManager.primary,
                  ),
                  SizedBox(width: AppWidth.s8),
                  CustomText(
                    text: AppTranslation.updateLocation,
                    textStyle: getMediumStyle(
                      color: ColorManager.primary,
                      fontSize: AppFontSize.s15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: onChangePassword,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppPadding.p8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 20, color: ColorManager.primary),
                  SizedBox(width: AppWidth.s8),
                  CustomText(
                    text: AppTranslation.changePasswordTitle,
                    textStyle: getMediumStyle(
                      color: ColorManager.primary,
                      fontSize: AppFontSize.s15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          CustomButton(
            text: AppTranslation.save,
            onPressed: isLoading ? null : onUpdate,
            color: ColorManager.primary,
          ),
          if (!user.isGuest)
            CustomButton(
              text: AppTranslation.deleteAccount,
              onPressed: isLoading ? null : onDeleteAccount,
              isOutlined: true,
              color: ColorManager.errorColor,
            ),
        ],
      ),
    );
  }
}

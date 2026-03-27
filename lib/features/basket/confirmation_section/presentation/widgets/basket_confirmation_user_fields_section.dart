import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';

/// Full name, street, extra address notes, phone.
class BasketConfirmationUserFieldsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController streetController;
  final TextEditingController addressDetailsController;
  final TextEditingController phoneController;
  final ValueChanged<String>? onStreetChanged;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onAddressDetailsChanged;
  final ValueChanged<String>? onPhoneChanged;

  const BasketConfirmationUserFieldsSection({
    super.key,
    required this.nameController,
    required this.streetController,
    required this.addressDetailsController,
    required this.phoneController,
    this.onStreetChanged,
    this.onNameChanged,
    this.onAddressDetailsChanged,
    this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          title: AppTranslation.fullName,
          hintText: AppTranslation.enterFullName,
          controller: nameController,
          onChanged: onNameChanged,
          textColor: ColorManager.productNameColor,
          hintColor: ColorManager.textSecondary,
        ),
        SizedBox(height: AppHeight.s12),
        CustomTextField(
          title: AppTranslation.street,
          hintText: AppTranslation.street,
          controller: streetController,
          onChanged: onStreetChanged,
          textColor: ColorManager.productNameColor,
          hintColor: ColorManager.textSecondary,
        ),
        SizedBox(height: AppHeight.s12),
        CustomTextField(
          title: AppTranslation.addressDetails,
          hintText: AppTranslation.enterAddress,
          controller: addressDetailsController,
          onChanged: onAddressDetailsChanged,
          textColor: ColorManager.productNameColor,
          hintColor: ColorManager.textSecondary,
        ),
        SizedBox(height: AppHeight.s12),
        CustomTextField(
          title: AppTranslation.phone,
          hintText: AppTranslation.enterPhone,
          controller: phoneController,
          onChanged: onPhoneChanged,
          keyboardType: TextInputType.phone,
          textColor: ColorManager.productNameColor,
          hintColor: ColorManager.textSecondary,
        ),
      ],
    );
  }
}

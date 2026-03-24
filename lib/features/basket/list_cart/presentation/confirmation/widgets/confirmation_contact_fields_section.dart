import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';

class ConfirmationContactFieldsSection extends StatelessWidget {
  final TextEditingController streetController;
  final TextEditingController addressDetailsController;
  final TextEditingController phoneController;
  final ValueChanged<String>? onStreetChanged;

  const ConfirmationContactFieldsSection({
    super.key,
    required this.streetController,
    required this.addressDetailsController,
    required this.phoneController,
    this.onStreetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          title: AppTranslation.street,
          hintText: AppTranslation.street,
          controller: streetController,
          onChanged: onStreetChanged,
          filledColor: ColorManager.surface,
          textColor: ColorManager.productNameColor,
          hintColor: ColorManager.textSecondary,
        ),
        SizedBox(height: AppHeight.s12),
        CustomTextField(
          title: AppTranslation.addressDetails,
          hintText: AppTranslation.enterAddress,
          controller: addressDetailsController,
          filledColor: ColorManager.surface,
          textColor: ColorManager.productNameColor,
          hintColor: ColorManager.textSecondary,
        ),
        SizedBox(height: AppHeight.s12),
        CustomTextField(
          title: AppTranslation.phone,
          hintText: AppTranslation.enterPhone,
          controller: phoneController,
          keyboardType: TextInputType.phone,
          filledColor: ColorManager.surface,
          textColor: ColorManager.productNameColor,
          hintColor: ColorManager.textSecondary,
        ),
      ],
    );
  }
}

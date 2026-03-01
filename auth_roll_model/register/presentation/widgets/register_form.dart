import 'package:flutter/material.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_password_field.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_display.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_dropdown.dart';
import 'package:jeeb_admin/core/presentation/localization/app_translation.dart';
import 'package:jeeb_admin/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_admin/core/presentation/routes/routes.dart';
import 'package:jeeb_admin/features/country/presentation/widgets/country_city_widget.dart';
import 'package:jeeb_admin/features/country/domain/entities/country_entity.dart';
import 'package:jeeb_admin/features/city/domain/entities/city_entity.dart';

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final String? selectedRole;
  final String? selectedNotificationChannel;
  final CountryEntity? selectedCountry;
  final CityEntity? selectedCity;
  final ValueChanged<CountryEntity?> onCountryChanged;
  final ValueChanged<CityEntity?> onCityChanged;
  final ValueChanged<String?> onRoleChanged;
  final ValueChanged<String?> onNotificationChannelChanged;
  final VoidCallback onRegister;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    required this.addressController,
    this.selectedRole,
    this.selectedNotificationChannel,
    this.selectedCountry,
    this.selectedCity,
    required this.onCountryChanged,
    required this.onCityChanged,
    required this.onRoleChanged,
    required this.onNotificationChannelChanged,
    required this.onRegister,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            title: AppTranslation.firstName,
            hintText: AppTranslation.firstName,
            controller: firstNameController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomTextField(
            title: AppTranslation.lastName,
            hintText: AppTranslation.lastName,
            controller: lastNameController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomTextField(
            title: AppTranslation.email,
            hintText: AppTranslation.enterEmail,
            controller: emailController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomTextField(
            title: AppTranslation.phone,
            hintText: AppTranslation.enterPhone,
            controller: phoneController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomPasswordField(
            title: AppTranslation.password,
            hintText: AppTranslation.enterPassword,
            controller: passwordController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomTextField(
            title: AppTranslation.address,
            hintText: AppTranslation.enterAddress,
            controller: addressController,
          ),
          SizedBox(height: AppHeight.s24),
          CountryCityWidget(
            selectedCountry: selectedCountry,
            selectedCity: selectedCity,
            onSelectCountry: onCountryChanged,
            onSelectCity: onCityChanged,
            isRequired: true,
          ),
          SizedBox(height: AppHeight.s24),
          CustomDropdown<String>(
            title: AppTranslation.notificationChannel,
            value: selectedNotificationChannel,
            hintText: AppTranslation.notificationChannel,
            items: const [
              DropdownMenuItem<String>(value: 'EMAIL', child: Text('EMAIL')),
              DropdownMenuItem<String>(
                value: 'WHATSAPP',
                child: Text('WHATSAPP'),
              ),
            ],
            onChanged: onNotificationChannelChanged,
          ),
          SizedBox(height: AppHeight.s32),
          CustomButton(
            text: AppTranslation.register,
            onPressed: onRegister,
            isLoading: isLoading,
            color: ColorManager.primary,
          ),
          SizedBox(height: AppHeight.s24),
          CustomDropdown<String>(
            title: 'Role (Admin or Merchant)',
            value: selectedRole,
            hintText: 'Select Role',
            items: const [
              DropdownMenuItem<String>(
                value: 'MERCHANT',
                child: Text('MERCHANT'),
              ),
              DropdownMenuItem<String>(value: 'ADMIN', child: Text('ADMIN')),
            ],
            onChanged: onRoleChanged,
          ),
          SizedBox(height: AppHeight.s24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextDisplay(
                text: AppTranslation.alreadyHaveAccount,
                fontSize: AppFontSize.s14,
                color: ColorManager.textColor,
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(Routes.login);
                },
                child: CustomTextDisplay(
                  text: AppTranslation.login,
                  fontSize: AppFontSize.s14,
                  color: ColorManager.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

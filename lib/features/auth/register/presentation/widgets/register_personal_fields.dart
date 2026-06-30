import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/features/auth/register/presentation/bloc/register_bloc.dart';

class RegisterPersonalFields extends StatelessWidget {
  final RegisterBloc bloc;

  /// Clients (CUSTOMER) only enter name, phone and password.
  /// Other roles (e.g. DELIVERY) still capture email and address.
  final bool isCustomer;

  const RegisterPersonalFields({
    super.key,
    required this.bloc,
    this.isCustomer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppHeight.s24,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          title: AppTranslation.firstName,
          hintText: AppTranslation.firstName,
          controller: bloc.firstNameController,
        ),
        CustomTextField(
          title: AppTranslation.lastName,
          hintText: AppTranslation.lastName,
          controller: bloc.lastNameController,
        ),
        if (!isCustomer)
          CustomTextField(
            title: AppTranslation.email,
            hintText: AppTranslation.enterEmail,
            controller: bloc.emailController,
          ),
        CustomTextField(
          keyboardType: TextInputType.phone,
          title: AppTranslation.phone,
          hintText: AppTranslation.enterPhone,
          controller: bloc.phoneController,
        ),
        CustomTextField(
          obscureText: true,
          showObscureTextToggle: true,
          title: AppTranslation.password,
          hintText: AppTranslation.enterPassword,
          controller: bloc.passwordController,
        ),
        if (!isCustomer)
          CustomTextField(
            title: AppTranslation.address,
            hintText: AppTranslation.enterAddress,
            controller: bloc.addressController,
          ),
      ],
    );
  }
}

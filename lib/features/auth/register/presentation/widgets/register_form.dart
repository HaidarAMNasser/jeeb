import 'package:flutter/material.dart';
// import 'dart:io' show File; // used for ID image preview, commented with ID pickers

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
// import 'package:jeeb_app/core/common/utils/date_input_formatter.dart';
import 'package:jeeb_app/core/presentation/widgets/avatar_image_picker.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/register/presentation/bloc/register_bloc.dart';
import 'package:jeeb_app/features/auth/register/presentation/widgets/location_source_selector.dart';
import 'package:jeeb_app/features/country/presentation/widgets/country_city_widget.dart';

class RegisterForm extends StatelessWidget {
  final VoidCallback onRegister;
  final Future<void> Function() onUseMyLocation;
  final VoidCallback onPickImage;
  final VoidCallback onPickIdFront;
  final VoidCallback onPickIdBack;

  const RegisterForm({
    super.key,
    required this.onRegister,
    required this.onUseMyLocation,
    required this.onPickImage,
    required this.onPickIdFront,
    required this.onPickIdBack,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RegisterBloc>();

    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        String? imagePath;
        final imageFile = bloc.selectedImageFile;
        if (imageFile != null) {
          if (imageFile is String) {
            imagePath = imageFile;
          } else {
            final dynamic dynamicFile = imageFile;
            final path = dynamicFile.path as String?;
            if (path != null && path.isNotEmpty) {
              imagePath = path;
            }
          }
        }
        String? initial;
        if (bloc.firstNameController.text.isNotEmpty) {
          initial = bloc.firstNameController.text[0].toUpperCase();
        }
        return Form(
          key: bloc.formKey,
          child: Column(
            spacing: AppHeight.s24,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if ((bloc.selectedRole ?? 'CUSTOMER') != 'DELIVERY')
                AvatarImagePicker(
                  key: ValueKey(bloc.imageVersion),
                  imagePath: imagePath,
                  fallbackInitial: initial,
                  onTap: onPickImage,
                ),
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
                title: AppTranslation.password,
                hintText: AppTranslation.enterPassword,
                controller: bloc.passwordController,
              ),
              CustomTextField(
                title: AppTranslation.address,
                hintText: AppTranslation.enterAddress,
                controller: bloc.addressController,
              ),
              LocationSourceSelector(
                title: AppTranslation.location,
                useMyLocationHint: AppTranslation.useMyLocation,
                locationSetHint: AppTranslation.locationSetFormat,
                latitude: state.useLocationLat,
                longitude: state.useLocationLng,
                isRequired: true,
                onUseMyLocation: onUseMyLocation,
                onClearLocation:
                    (state.useLocationLat != null ||
                        state.useLocationLng != null)
                    ? () => bloc.add(const RegisterLocationCleared())
                    : null,
                isLoading: state.isLocationLoading,
              ),
              CountryCityWidget(
                selectedCountry: state.selectedCountry,
                selectedCity: state.selectedCity,
                onSelectCountry: (country) {
                  bloc.add(RegisterCountryChanged(country ));
                },
                onSelectCity: (city) {
                  bloc.add(RegisterCityChanged(city));
                },
                isRequired: true,
                isReadOnly: false,
              ),
              CustomButton(
                text: AppTranslation.register,
                onPressed: onRegister,
                color: ColorManager.primary,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: AppTranslation.alreadyHaveAccount,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pushNamed(Routes.login);
                    },
                    child: CustomText(
                      text: AppTranslation.login,
                      textStyle: getMediumStyle(
                        fontSize: AppFontSize.s14,
                        color: ColorManager.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

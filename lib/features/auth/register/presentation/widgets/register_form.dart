import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/avatar_image_picker.dart';
import 'package:jeeb_app/features/auth/register/presentation/bloc/register_bloc.dart';
import 'package:jeeb_app/features/auth/register/presentation/widgets/location_source_selector.dart';
import 'package:jeeb_app/features/auth/register/presentation/widgets/register_form_footer.dart';
import 'package:jeeb_app/features/auth/register/presentation/widgets/register_personal_fields.dart';
import 'package:jeeb_app/features/country/presentation/widgets/country_city_widget.dart';

class RegisterForm extends StatelessWidget {
  final VoidCallback onRegister;
  final Future<void> Function() onPickLocation;
  final VoidCallback onPickImage;
  final VoidCallback onPickIdFront;
  final VoidCallback onPickIdBack;

  const RegisterForm({
    super.key,
    required this.onRegister,
    required this.onPickLocation,
    required this.onPickImage,
    required this.onPickIdFront,
    required this.onPickIdBack,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RegisterBloc>();

    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        final imagePath = _resolveImagePath(bloc.selectedImageFile);
        final initial = bloc.firstNameController.text.isNotEmpty
            ? bloc.firstNameController.text[0].toUpperCase()
            : null;

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
              RegisterPersonalFields(bloc: bloc),
              LocationSourceSelector(
                title: AppTranslation.location,
                useMyLocationHint: AppTranslation.pleaseSelectLocation,
                locationSetFallbackHint: AppTranslation.locationSetFormat,
                latitude: state.useLocationLat,
                longitude: state.useLocationLng,
                displayCountry: state.locationDisplayCountry,
                displayCity: state.locationDisplayCity,
                displayStreet: state.locationDisplayStreet,
                isRequired: true,
                onPickLocation: () => onPickLocation(),
                onClearLocation: _clearLocationIfAny(state, bloc),
                isLoading: state.isLocationLoading,
              ),
              CountryCityWidget(
                selectedCountry: state.selectedCountry,
                selectedCity: state.selectedCity,
                onSelectCountry: (c) => bloc.add(RegisterCountryChanged(c)),
                onSelectCity: (c) => bloc.add(RegisterCityChanged(c)),
                isRequired: true,
                isReadOnly: false,
              ),
              RegisterFormFooter(onRegister: onRegister),
            ],
          ),
        );
      },
    );
  }

  static String? _resolveImagePath(dynamic imageFile) {
    if (imageFile == null) return null;
    if (imageFile is String) return imageFile;
    final path = imageFile.path as String?;
    if (path != null && path.isNotEmpty) return path;
    return null;
  }

  static VoidCallback? _clearLocationIfAny(
    RegisterState state,
    RegisterBloc bloc,
  ) {
    if (state.useLocationLat == null && state.useLocationLng == null) {
      return null;
    }
    return () => bloc.add(const RegisterLocationCleared());
  }
}

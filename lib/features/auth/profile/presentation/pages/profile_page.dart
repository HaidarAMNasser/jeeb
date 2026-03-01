import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_service.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';
import 'package:jeeb_app/features/country/presentation/bloc/country_bloc.dart';
import 'package:jeeb_app/features/city/presentation/bloc/city_bloc.dart';
import 'package:jeeb_app/features/country/presentation/widgets/country_city_widget.dart';
import 'package:jeeb_app/features/auth/domain/entities/user_entity.dart';
import '../bloc/profile_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  CountryEntity? _selectedCountry;
  CityEntity? _selectedCity;
  UserEntity? _userFromProfile;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileBloc>().add(const GetProfile());
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(
            UpdateProfile(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              phone: _phoneController.text.trim(),
              countryId: _selectedCountry?.id,
              cityId: _selectedCity?.id,
              address: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
            ),
          );
    }
  }

  Future<void> _handleLogout() async {
    await di.sl<StorageService>().clearStorage(clearAuthParams: true);
    if (!mounted) return;
    di.sl<NavigationService>().pushNamedAndRemoveUntil(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CountryBloc, CountryState>(
      listener: (context, countryState) {
        final user = _userFromProfile;
        if (user == null) return;
        if (countryState is CountryLoaded) {
          try {
            final c = countryState.countries
                .firstWhere((e) => e.id == user.countryId);
            if (mounted) setState(() => _selectedCountry = c);
            context.read<CityBloc>().add(LoadCities(
                  countryId: user.countryId,
                  withLoading: true,
                ));
          } catch (_) {}
        }
      },
      child: BlocListener<CityBloc, CityState>(
        listener: (context, cityState) {
          final user = _userFromProfile;
          if (user == null || _selectedCountry == null) return;
          if (cityState is CityLoaded) {
            try {
              final cityId = user.cityId;
              final city = cityState.cities
                  .firstWhere((e) => (e as CityEntity).id == cityId);
              if (mounted) setState(() => _selectedCity = city);
            } catch (_) {}
          }
        },
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              _userFromProfile = state.user;
              _firstNameController.text = state.user.firstName;
              _lastNameController.text = state.user.lastName;
              _phoneController.text = state.user.phone;
              _addressController.text = state.user.address ?? '';
              final countryState = context.read<CountryBloc>().state;
              if (countryState is CountryLoaded) {
                try {
                  final c = countryState.countries
                      .firstWhere((e) => e.id == state.user.countryId);
                  if (mounted) setState(() => _selectedCountry = c);
                  context.read<CityBloc>().add(LoadCities(
                        countryId: state.user.countryId,
                        withLoading: true,
                      ));
                } catch (_) {}
              }
            } else if (state is ProfileUpdated) {
              _userFromProfile = state.user;
          _firstNameController.text = state.user.firstName;
          _lastNameController.text = state.user.lastName;
          _phoneController.text = state.user.phone;
          _addressController.text = state.user.address ?? '';
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated')),
              );
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
        final isLoading = state is ProfileLoading;
        return Scaffold(
          backgroundColor: ColorManager.background,
          appBar: AppBar(
            backgroundColor: ColorManager.background,
            elevation: 0,
            title: CustomText(
              text: AppTranslation.profile,
              textStyle: TextStyle(
                color: ColorManager.titlesColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(AppPadding.p24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state is ProfileLoaded || state is ProfileUpdated) ...[
                          CustomText(
                            text: state is ProfileLoaded
                                ? state.user.fullName
                                : (state as ProfileUpdated).user.fullName,
                            textStyle: TextStyle(
                              color: ColorManager.titlesColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppHeight.s8),
                          CustomText(
                            text: state is ProfileLoaded
                                ? state.user.email
                                : (state as ProfileUpdated).user.email,
                            textStyle: TextStyle(
                              color: ColorManager.textColor,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: AppHeight.s24),
                        ],
                        CustomTextField(
                          label: AppTranslation.firstName,
                          hint: AppTranslation.firstName,
                          controller: _firstNameController,
                        ),
                        SizedBox(height: AppHeight.s16),
                        CustomTextField(
                          label: AppTranslation.lastName,
                          hint: AppTranslation.lastName,
                          controller: _lastNameController,
                        ),
                        SizedBox(height: AppHeight.s16),
                        CustomTextField(
                          label: AppTranslation.phone,
                          hint: AppTranslation.enterPhone,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: AppHeight.s16),
                        CountryCityWidget(
                          selectedCountry: _selectedCountry,
                          selectedCity: _selectedCity,
                          isRequired: false,
                          onSelectCountry: (c) =>
                              setState(() => _selectedCountry = c),
                          onSelectCity: (c) =>
                              setState(() => _selectedCity = c),
                        ),
                        SizedBox(height: AppHeight.s16),
                        CustomTextField(
                          label: AppTranslation.address,
                          hint: AppTranslation.enterAddress,
                          controller: _addressController,
                          maxLines: 2,
                        ),
                        SizedBox(height: AppHeight.s32),
                        CustomButton(
                          text: AppTranslation.save,
                          onPressed: _handleUpdate,
                          isLoading: isLoading,
                          color: ColorManager.primary,
                        ),
                        SizedBox(height: AppHeight.s24),
                        OutlinedButton(
                          onPressed: _handleLogout,
                          child: Text(AppTranslation.logout),
                        ),
                      ],
                    ),
                  ),
                ),
        );
          },
        ),
      ),
    );
  }
}

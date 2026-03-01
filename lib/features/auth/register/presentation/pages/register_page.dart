import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';
import '../bloc/register_bloc.dart';
import '../widgets/register_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedRole = 'MERCHANT';
  String? _selectedNotificationChannel = 'EMAIL';
  CountryEntity? _selectedCountry;
  CityEntity? _selectedCity;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onCountryChanged(CountryEntity? country) {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
    });
  }

  void _onCityChanged(CityEntity? city) {
    setState(() {
      _selectedCity = city;
    });
  }

  // Fake register function for testing - bypasses actual registration
  Future<void> _handleFakeRegister() async {
    try {
      final storageService = di.sl<StorageService>();

      // Set fake token for testing
      await storageService.setUserToken('fake_token_for_testing');

      // Set user role to admin (lowercase as stored in login)
      await storageService.setUserRole(UserRole.merchant.name);

      customToast(msg: 'Fake registration successful (Testing Mode - Admin)');

      // Navigate to main navigation
      if (mounted) {
        context.pushNamedAndRemoveUntil(
          Routes.mainNavigation,
          predicate: (route) => false,
        );
      }
    } catch (e) {
      customToast(msg: 'Error in fake register: $e');
    }
  }

  // Original register function - kept for future use when real registration is needed
  // ignore: unused_element
  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCountry == null) {
        customToast(msg: AppTranslation.pleaseSelectCountry);
        return;
      }
      if (_selectedCity == null) {
        customToast(msg: AppTranslation.pleaseSelectCity);
        return;
      }

      context.read<RegisterBloc>().add(
        RegisterSubmitted(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phone: _phoneController.text.trim(),
          role: _selectedRole!,
          countryId: _selectedCountry!.id,
          cityId: _selectedCity!.id,
          notificationChannel: _selectedNotificationChannel!,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          customToast(msg: AppTranslation.registerSuccess);
          context.pushNamed(Routes.verify, arguments: {'email': state.email});
        } else if (state is RegisterError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          progressIndicator: const CustomCircleIndicator(),
          inAsyncCall: state is RegisterLoading,
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: CustomAppBar(title: AppTranslation.register),

            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppPadding.p24),
                child: RegisterForm(
                  formKey: _formKey,
                  firstNameController: _firstNameController,
                  lastNameController: _lastNameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  phoneController: _phoneController,
                  addressController: _addressController,
                  selectedRole: _selectedRole,
                  selectedNotificationChannel: _selectedNotificationChannel,
                  selectedCountry: _selectedCountry,
                  selectedCity: _selectedCity,
                  onCountryChanged: _onCountryChanged,
                  onCityChanged: _onCityChanged,
                  onRoleChanged: (role) => setState(() => _selectedRole = role),
                  onNotificationChannelChanged: (channel) =>
                      setState(() => _selectedNotificationChannel = channel),
                  onRegister:
                      _handleFakeRegister, // Using fake register for testing
                  isLoading: state is RegisterLoading,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

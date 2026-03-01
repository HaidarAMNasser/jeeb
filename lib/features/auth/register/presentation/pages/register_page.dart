import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';
import 'package:jeeb_app/features/country/presentation/widgets/country_city_widget.dart';
import '../bloc/register_bloc.dart';

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
  CountryEntity? _selectedCountry;
  CityEntity? _selectedCity;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCountry == null || _selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select country and city')),
        );
        return;
      }
      context.read<RegisterBloc>().add(
            RegisterSubmitted(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              phone: _phoneController.text.trim(),
              role: 'CUSTOMER',
              countryId: _selectedCountry!.id,
              cityId: _selectedCity!.id,
              notificationChannel: 'EMAIL',
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful')),
          );
          context.pushNamedAndRemoveUntil(
            Routes.login,
            predicate: (_) => false,
          );
        } else if (state is RegisterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is RegisterLoading;
        return Scaffold(
          backgroundColor: ColorManager.background,
          appBar: AppBar(
            backgroundColor: ColorManager.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: CustomText(
              text: AppTranslation.register,
              textStyle: TextStyle(
                color: ColorManager.titlesColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(AppPadding.p24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                            label: AppTranslation.email,
                            hint: AppTranslation.enterEmail,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: AppHeight.s16),
                          CustomTextField(
                            label: AppTranslation.password,
                            hint: AppTranslation.enterPassword,
                            controller: _passwordController,
                            obscureText: true,
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
                            isRequired: true,
                            onSelectCountry: (c) =>
                                setState(() => _selectedCountry = c),
                            onSelectCity: (c) =>
                                setState(() => _selectedCity = c),
                          ),
                          SizedBox(height: AppHeight.s32),
                          CustomButton(
                            text: AppTranslation.register,
                            onPressed: _handleRegister,
                            isLoading: isLoading,
                            color: ColorManager.primary,
                          ),
                          SizedBox(height: AppHeight.s24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: AppTranslation.alreadyHaveAccount,
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: ColorManager.textColor,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.pushNamed(Routes.login),
                                child: CustomText(
                                  text: AppTranslation.login,
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: ColorManager.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

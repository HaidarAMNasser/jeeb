import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/language_selection_dialog.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_service.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:easy_localization/easy_localization.dart';
import '../bloc/profile_bloc.dart';
import '../../../logout/presentation/bloc/logout_bloc.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

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
  bool _isProfileLoaded = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileBloc>().add(const GetProfile());
      }
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

  void _handleUpdateProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(
            UpdateProfile(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
            ),
          );
    }
  }

  void _handleLogout() {
    context.read<LogoutBloc>().add(const LogoutSubmitted());
  }

  Future<void> _handleChangeLanguage() async {
    final storageService = di.sl<StorageService>();
    final currentLanguage = storageService.getAppLanguage();
    
    final selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => LanguageSelectionDialog(
        currentLanguage: currentLanguage.isEmpty ? null : currentLanguage,
      ),
    );

    if (selectedLanguage != null && selectedLanguage != currentLanguage && mounted) {
      // Save selected language
      await storageService.setAppLanguage(selectedLanguage);
      
      // Update app locale
      await context.setLocale(Locale(selectedLanguage));
      
      // Show success message
      customToast(msg: AppTranslation.languageChangedSuccessfully);
      
      // Restart the app to apply language changes
      // Note: In a real app, you might want to use a package like flutter_restart
      // For now, we'll just show a toast and the language will change on next app restart
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogoutBloc, LogoutState>(
      listener: (context, logoutState) {
        if (logoutState is LogoutSuccess) {
          customToast(msg: AppTranslation.logoutSuccess);
          // Navigate to login screen after clearing storage
          // Storage is already cleared in the logout bloc before emitting success
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationService().pushNamedAndRemoveUntil(Routes.login);
          });
        } else if (logoutState is LogoutError) {
          customToast(msg: logoutState.message);
        }
      },
      builder: (context, logoutState) {
        return BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              if (!_isProfileLoaded) {
                // Initial load - update controllers
                _firstNameController.text = state.user.firstName;
                _lastNameController.text = state.user.lastName;
                _phoneController.text = state.user.phone;
                _addressController.text = state.user.address ?? '';
                _isProfileLoaded = true;
              } else {
                // This is an update after initial load, show success toast
                customToast(msg: AppTranslation.profileUpdatedSuccess);
              }
            } else if (state is ProfileError) {
              customToast(msg: state.message);
            }
          },
          builder: (context, state) {
            // Use ModalProgressHUD only for update (PATCH) and logout (POST) operations
            // Initial profile fetch (GET) uses BlocStateHandler
            final isUpdateLoading = state is ProfileLoading && _isProfileLoaded;
            final isLogoutLoading = logoutState is LogoutLoading;
            final showProgressHUD = isUpdateLoading || isLogoutLoading;

            return ModalProgressHUD(
              progressIndicator: const CustomCircleIndicator(),
              inAsyncCall: showProgressHUD,
              child: Scaffold(
                backgroundColor: ColorManager.background,
                appBar: CustomAppBar(
                  title: AppTranslation.profile,
                ),
                body: BlocStateHandler<ProfileBloc, ProfileState>(
                  bloc: context.read<ProfileBloc>(),
                  isLoading: (state) => state is ProfileLoading && !_isProfileLoaded,
                  isError: (state) => state is ProfileError && !_isProfileLoaded,
                  getErrorMessage: (state) => (state as ProfileError).message,
                  isSuccess: (state) => state is ProfileLoaded,
                  getRetryCallback: (state) => () {
                    context.read<ProfileBloc>().add(const GetProfile());
                  },
                  successBuilder: (context, profileState) {
                    final loadedState = profileState as ProfileLoaded;

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(AppPadding.p24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileHeader(user: loadedState.user),
                          SizedBox(height: AppHeight.s32),
                          ProfileForm(
                            formKey: _formKey,
                            firstNameController: _firstNameController,
                            lastNameController: _lastNameController,
                            phoneController: _phoneController,
                            addressController: _addressController,
                            onUpdate: _handleUpdateProfile,
                            isLoading: isUpdateLoading,
                          ),
                          SizedBox(height: AppHeight.s24),
                          CustomButton(
                            text: AppTranslation.changeLanguage,
                            onPressed: _handleChangeLanguage,
                            isLoading: false,
                            color: ColorManager.primary,
                            isOutlined: true,
                          ),
                          SizedBox(height: AppHeight.s16),
                          CustomButton(
                            text: AppTranslation.logout,
                            onPressed: _handleLogout,
                            isLoading: isLogoutLoading,
                            color: ColorManager.error,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

}


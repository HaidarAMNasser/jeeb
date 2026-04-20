import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_service.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/language_selection_dialog.dart';
import 'package:jeeb_app/core/presentation/widgets/logout_dialog.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_map_picker_page.dart';
import 'package:jeeb_app/features/auth/profile/presentation/widgets/profile_page_content.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../bloc/profile_bloc.dart';
import '../../../logout/presentation/bloc/logout_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogoutBloc, LogoutState>(
      listener: (context, logoutState) {
        if (logoutState is LogoutSuccess) {
          customToast(msg: AppTranslation.logoutSuccess);
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => NavigationService().pushNamedAndRemoveUntil(Routes.login),
          );
        } else if (logoutState is LogoutError) {
          customToast(msg: logoutState.message);
        }
      },
      builder: (context, logoutState) {
        return BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              if (state.updateFailureMessage != null) {
                final route = ModalRoute.of(context);
                if (route?.isCurrent ?? true) {
                  customToast(msg: state.updateFailureMessage!);
                  context.read<ProfileBloc>().add(const ClearProfileUpdateFailure());
                }
              }
              if (!state.formValuesInitialized) {
                _firstNameController.text = state.user.firstName;
                _lastNameController.text = state.user.lastName;
                _phoneController.text = state.user.phone;
                _addressController.text = state.user.address ?? '';
                context.read<ProfileBloc>().add(const FormValuesInitialized());
              } else if (state.updateSuccess) {
                final route = ModalRoute.of(context);
                if (route?.isCurrent ?? true) {
                  customToast(msg: AppTranslation.profileUpdatedSuccess);
                  context.read<ProfileBloc>().add(const ClearUpdateSuccess());
                }
              }
              if (state.localeToApply != null) {
                context.setLocale(state.localeToApply!);
                customToast(msg: AppTranslation.languageChangedSuccessfully);
                context.read<ProfileBloc>().add(const ClearLocaleToApply());
              }
            } else if (state is ProfileError) {
              customToast(msg: state.message);
            }
          },
          builder: (context, state) {
            final loaded = state is ProfileLoaded ? state : null;
            final isUpdateLoading = loaded?.isUpdating ?? false;
            final isLogoutLoading = logoutState is LogoutLoading;
            return ModalProgressHUD(
              progressIndicator: const CustomCircleIndicator(),
              inAsyncCall: isUpdateLoading || isLogoutLoading,
              child: Scaffold(
                backgroundColor: ColorManager.background,
                appBar: CustomAppBar(
                  title: AppTranslation.profile,
                  actions: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppPadding.p10),
                      child: IconButton(
                        icon: const Icon(Icons.logout),
                        color: ColorManager.defaultWhite,
                        onPressed: () async {
                          final ok = await showLogoutDialog(context);
                          if (ok == true && mounted) {
                            context.read<LogoutBloc>().add(
                              const LogoutSubmitted(),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                body: BlocStateHandler<ProfileBloc, ProfileState>(
                  bloc: context.read<ProfileBloc>(),
                  isLoading: (s) => s is ProfileLoading,
                  isError: (s) => s is ProfileError && loaded == null,
                  getErrorMessage: (s) => (s as ProfileError).message,
                  isSuccess: (s) => s is ProfileLoaded,
                  getRetryCallback: (_) =>
                      () => context.read<ProfileBloc>().add(const GetProfile()),
                  successBuilder: (context, profileState) {
                    final loadedState = profileState as ProfileLoaded;
                    return ProfilePageContent(
                      user: loadedState.user,
                      formKey: _formKey,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      isMerchant: loadedState.isMerchant,
                      onUpdate: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<ProfileBloc>().add(
                            SaveProfile(
                              firstName: _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              address: _addressController.text.trim().isEmpty
                                  ? null
                                  : _addressController.text.trim(),
                            ),
                          );
                        }
                      },
                      onChangeLanguage: () => _showLanguageDialog(context),
                      onUpdateLocation: () =>
                          _openMapPicker(context, loadedState),
                      onAccountStatusChanged: (v) => context
                          .read<ProfileBloc>()
                          .add(UpdateAccountActive(v)),
                      onChangePassword: () =>
                          context.pushNamed(Routes.changePassword),
                      isUpdateLoading: isUpdateLoading,
                      onPickImage: () => _pickAndUpdateImage(context),
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

  Future<void> _showLanguageDialog(BuildContext context) async {
    final storage = di.sl<StorageService>();
    final current = storage.getAppLanguage();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => LanguageSelectionDialog(
        currentLanguage: current.isEmpty ? null : current,
      ),
    );
    if (selected != null && selected != current && mounted) {
      context.read<ProfileBloc>().add(ChangeLanguage(selected));
    }
  }

  Future<void> _pickAndUpdateImage(BuildContext context) async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile != null && context.mounted) {
      context.read<ProfileBloc>().add(UpdateProfile(imageFile: xFile));
    }
  }

  Future<void> _openMapPicker(
    BuildContext context,
    ProfileLoaded loaded,
  ) async {
    final result = await Navigator.of(context).push<LocationMapPickerResult>(
      MaterialPageRoute(
        builder: (ctx) => LocationMapPickerPage(
          initialLatitude: loaded.user.currentLat,
          initialLongitude: loaded.user.currentLng,
        ),
      ),
    );
    if (result != null && context.mounted) {
      context.read<ProfileBloc>().add(
        UpdateLocation(latitude: result.latitude, longitude: result.longitude),
      );
    }
  }
}

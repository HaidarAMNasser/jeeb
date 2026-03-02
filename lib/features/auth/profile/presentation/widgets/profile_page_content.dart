import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';
import 'profile_header.dart';
import 'profile_form.dart';

/// Pure UI: profile form, change language and logout buttons.
class ProfilePageContent extends StatelessWidget {
  final UserEntity user;
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final VoidCallback onUpdate;
  final bool isUpdateLoading;
  final VoidCallback onChangeLanguage;
  final VoidCallback onLogout;
  final bool isLogoutLoading;

  const ProfilePageContent({
    super.key,
    required this.user,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.addressController,
    required this.onUpdate,
    required this.isUpdateLoading,
    required this.onChangeLanguage,
    required this.onLogout,
    required this.isLogoutLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(user: user),
          SizedBox(height: AppHeight.s32),
          ProfileForm(
            formKey: formKey,
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            phoneController: phoneController,
            addressController: addressController,
            onUpdate: onUpdate,
            isLoading: isUpdateLoading,
            onChangeLanguage: onChangeLanguage,
          ),
        ],
      ),
    );
  }
}
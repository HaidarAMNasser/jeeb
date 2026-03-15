import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeeb_app/core/common/utils/location_permission_helper.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/auth/register/data/helpful_functions/register_form_validate.dart';

import '../bloc/register_bloc.dart';
import '../widgets/register_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  /// On Register tap: validate form, call register API, then navigate to verify on success.
  Future<void> _onRegisterTapped(BuildContext context) async {
    final bloc = context.read<RegisterBloc>();

    registerValidationToast(
      firstName: bloc.firstNameController.text.trim(),
      lastName: bloc.lastNameController.text.trim(),
      email: bloc.emailController.text.trim(),
      phone: bloc.phoneController.text.trim(),
      password: bloc.passwordController.text.trim(),
    );

    if (!isRegisterFormValid(
      firstName: bloc.firstNameController.text.trim(),
      lastName: bloc.lastNameController.text.trim(),
      email: bloc.emailController.text.trim(),
      phone: bloc.phoneController.text.trim(),
      password: bloc.passwordController.text.trim(),
    )) {
      return;
    }

    bloc.add(const RegisterSubmitted());
  }

  Future<void> _onPickImage(BuildContext context) async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile != null && context.mounted) {
      context.read<RegisterBloc>().add(RegisterImageChanged(xFile));
    }
  }

  Future<void> _onPickIdFront(BuildContext context) async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile != null && context.mounted) {
      context.read<RegisterBloc>().add(RegisterIdFrontChanged(xFile));
    }
  }

  Future<void> _onPickIdBack(BuildContext context) async {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile != null && context.mounted) {
      context.read<RegisterBloc>().add(RegisterIdBackChanged(xFile));
    }
  }

  Future<void> _onUseMyLocation(BuildContext context) async {
    final bloc = context.read<RegisterBloc>();

    bloc.add(const RegisterLocationLoadingChanged(true));
    final result = await LocationPermissionHelper.requestAndGetPosition();
    if (!context.mounted) return;

    bloc.add(const RegisterLocationLoadingChanged(false));

    if (result.latitude != null && result.longitude != null) {
      bloc.add(
        RegisterLocationUpdated(
          latitude: result.latitude!,
          longitude: result.longitude!,
        ),
      );
      return;
    }

    if (result.permissionGranted) {
      customToast(msg: AppTranslation.locationUnavailable);
    } else {
      customToast(msg: AppTranslation.locationPermissionDenied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    String? initialRole;
    if (args is Map && args['initialRole'] is String) {
      initialRole = args['initialRole'] as String;
    }
    final bloc = context.read<RegisterBloc>();
    if (initialRole != null && bloc.selectedRole != initialRole) {
      bloc.add(RegisterRoleChanged(initialRole));
    }

    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
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
                  onRegister: () => _onRegisterTapped(context),
                  onUseMyLocation: () => _onUseMyLocation(context),
                  onPickImage: () => _onPickImage(context),
                  onPickIdFront: () => _onPickIdFront(context),
                  onPickIdBack: () => _onPickIdBack(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

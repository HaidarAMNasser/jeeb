import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_password_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = _currentController.text.trim();
    final next = _newController.text.trim();
    final confirm = _confirmController.text.trim();
    if (next != confirm) {
      customToast(msg: AppTranslation.passwordsDoNotMatch);
      return;
    }
    context.read<ProfileBloc>().add(
          UpdateProfile(
            password: current,
            newPassword: next,
            confirmedPassword: confirm,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          if (state.updateFailureMessage != null) {
            customToast(msg: state.updateFailureMessage!);
            context.read<ProfileBloc>().add(const ClearProfileUpdateFailure());
          } else if (state.updateSuccess) {
            customToast(msg: AppTranslation.profileUpdatedSuccess);
            context.read<ProfileBloc>().add(const ClearUpdateSuccess());
            if (context.canPop()) {
              context.pop();
            }
          }
        } else if (state is ProfileError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, state) {
        final loading = state is ProfileLoaded && state.isUpdating;
        return ModalProgressHUD(
          progressIndicator: const CustomCircleIndicator(),
          inAsyncCall: loading,
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: CustomAppBar(title: AppTranslation.changePasswordTitle),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppPadding.p24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomPasswordField(
                        title: AppTranslation.oldPassword,
                        hintText: AppTranslation.enterPassword,
                        controller: _currentController,
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: () {
                            context.pushNamed(Routes.forgotPassword);
                          },
                          child: CustomText(
                            text: AppTranslation.forgotPassword,
                            textStyle: getMediumStyle(
                              fontSize: AppFontSize.s14,
                              color: ColorManager.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppHeight.s16),
                      CustomPasswordField(
                        title: AppTranslation.newPassword,
                        hintText: AppTranslation.enterPassword,
                        controller: _newController,
                      ),
                      SizedBox(height: AppHeight.s24),
                      CustomPasswordField(
                        title: AppTranslation.confirmNewPassword,
                        hintText: AppTranslation.enterPassword,
                        controller: _confirmController,
                      ),
                      SizedBox(height: AppHeight.s32),
                      CustomButton(
                        text: AppTranslation.save,
                        onPressed: loading ? null : _submit,
                        color: ColorManager.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

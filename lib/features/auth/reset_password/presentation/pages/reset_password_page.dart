import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';

import '../bloc/reset_password_bloc.dart';
import '../widgets/reset_password_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      final otp = _otpController.text.trim();
      final password = _passwordController.text.trim();

      if (otp.isEmpty) {
        customToast(msg: AppTranslation.pleaseEnterOtp);
        return;
      }
      if (password.isEmpty) {
        customToast(msg: AppTranslation.pleaseEnterPassword);
        return;
      }

      context.read<ResetPasswordBloc>().add(
        ResetPasswordSubmitted(
          email: widget.email,
          otp: otp,
          password: password,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordSuccess) {
          customToast(msg: AppTranslation.passwordResetSuccess);
          context.pushNamedAndRemoveUntil(
            Routes.login,
            predicate: (route) => false,
          );
        } else if (state is ResetPasswordError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          progressIndicator: const CustomCircleIndicator(),
          inAsyncCall: state is ResetPasswordLoading,
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: CustomAppBar(title: AppTranslation.resetPassword),

            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppPadding.p24),
                child: ResetPasswordForm(
                  formKey: _formKey,
                  otpController: _otpController,
                  passwordController: _passwordController,
                  onReset: _handleResetPassword,
                  isLoading: state is ResetPasswordLoading,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

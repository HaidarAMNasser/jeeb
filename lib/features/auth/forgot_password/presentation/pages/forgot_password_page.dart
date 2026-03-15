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
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/forgot_password/presentation/bloc/forgot_password_bloc.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        customToast(msg: AppTranslation.pleaseEnterEmail);
        return;
      }

      context.read<ForgotPasswordBloc>().add(
        ForgotPasswordSubmitted(email: email),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          customToast(msg: AppTranslation.otpSentSuccess);
          context.pushNamed(
            Routes.resetPassword,
            arguments: {'email': state.email},
          );
        } else if (state is ForgotPasswordError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          progressIndicator: const CustomCircleIndicator(),
          inAsyncCall: state is ForgotPasswordLoading,
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: CustomAppBar(title: AppTranslation.forgotPassword),

            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppPadding.p24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppHeight.s50),
                      Text(
                        AppTranslation.forgotPassword,
                        style: getBoldStyle(
                          fontSize: AppFontSize.s24,
                          color: ColorManager.titlesColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppHeight.s8),
                      Text(
                        AppTranslation.forgotPasswordDescription,
                        style: getRegularStyle(
                          fontSize: AppFontSize.s14,
                          color: ColorManager.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppHeight.s50),
                      CustomTextField(
                        title: AppTranslation.email,
                        hintText: AppTranslation.enterEmail,
                        controller: _emailController,
                      ),
                      SizedBox(height: AppHeight.s32),
                      CustomButton(
                        text: AppTranslation.sendOtp,
                        onPressed: _handleForgotPassword,
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

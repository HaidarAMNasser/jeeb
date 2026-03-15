import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';

import '../bloc/login_bloc.dart';
import '../widgets/login_header.dart';
import '../widgets/login_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty) {
        customToast(msg: AppTranslation.pleaseEnterEmail);
        return;
      }
      if (password.isEmpty) {
        customToast(msg: AppTranslation.pleaseEnterPassword);
        return;
      }

      context.read<LoginBloc>().add(
            LoginSubmitted(
              email: email,
              password: password,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          customToast(msg: AppTranslation.loginSuccess);
          context.pushNamedAndRemoveUntil(
            Routes.mainNavigation,
            predicate: (route) => false,
          );
        } else if (state is LoginNeedsVerification) {
          context.pushNamedAndRemoveUntil(
            Routes.verify,
            predicate: (route) => false,
            arguments: {'email': state.email},
          );
        } else if (state is LoginError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          progressIndicator: const CustomCircleIndicator(),
          inAsyncCall: state is LoginLoading,
          child: Scaffold(
            backgroundColor: ColorManager.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppPadding.p24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LoginHeader(),
                    LoginForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      onLogin: _handleLogin,
                      isLoading: state is LoginLoading,
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


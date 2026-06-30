import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/auth/guest/presentation/bloc/guest_bloc.dart';
import 'package:jeeb_app/features/notification/update_token/presentation/bloc/update_token_bloc.dart';

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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePhoneLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final password = _passwordController.text.trim();

      if (_usePhoneLogin) {
        final phone = _phoneController.text.trim();
        if (phone.isEmpty) {
          customToast(msg: AppTranslation.pleaseEnterPhone);
          return;
        }
        if (password.isEmpty) {
          customToast(msg: AppTranslation.pleaseEnterPassword);
          return;
        }
        context.read<LoginBloc>().add(
          LoginSubmitted(
            usePhone: true,
            phone: phone,
            password: password,
          ),
        );
        return;
      }

      final email = _emailController.text.trim();
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
          usePhone: false,
          email: email,
          password: password,
        ),
      );
    }
  }

  void _handleGuestLogin() {
    context.read<GuestBloc>().add(const GuestLoginSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GuestBloc, GuestState>(
      listener: (context, guestState) {
        if (guestState is GuestSuccess) {
          context.read<UpdateTokenBloc>().add(
            const UpdateTokenLoginSucceeded(),
          );
          customToast(msg: AppTranslation.loginSuccess);
          context.pushNamedAndRemoveUntil(
            Routes.mainNavigation,
            predicate: (route) => false,
          );
        } else if (guestState is GuestError) {
          customToast(msg: guestState.message);
        }
      },
      builder: (context, guestState) {
        return BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              context.read<UpdateTokenBloc>().add(
                const UpdateTokenLoginSucceeded(),
              );
              customToast(msg: AppTranslation.loginSuccess);
              context.pushNamedAndRemoveUntil(
                Routes.mainNavigation,
                predicate: (route) => false,
              );
            } else if (state is LoginNeedsVerification) {
              context.pushNamedAndRemoveUntil(
                Routes.verify,
                predicate: (route) => false,
                arguments: {
                  'email': state.email,
                  'phone': state.phone,
                  'isCustomerPhone': state.isCustomerPhone,
                },
              );
            } else if (state is LoginError) {
              customToast(msg: state.message);
            }
          },
          builder: (context, state) {
            final isLoading =
                state is LoginLoading || guestState is GuestLoading;
            return ModalProgressHUD(
              progressIndicator: const CustomCircleIndicator(),
              inAsyncCall: isLoading,
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
                          phoneController: _phoneController,
                          passwordController: _passwordController,
                          usePhoneLogin: _usePhoneLogin,
                          onLoginMethodChanged: (usePhone) {
                            setState(() => _usePhoneLogin = usePhone);
                          },
                          onLogin: _handleLogin,
                          onGuestLogin: _handleGuestLogin,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

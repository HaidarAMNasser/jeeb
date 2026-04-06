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

import '../bloc/verify_bloc.dart';
import '../widgets/verify_header.dart';
import '../widgets/verify_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class VerifyPage extends StatefulWidget {
  final String email;

  const VerifyPage({super.key, required this.email});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    if (_formKey.currentState!.validate()) {
      final otp = _otpController.text.trim();
      if (otp.isEmpty) {
        customToast(msg: AppTranslation.pleaseEnterOtp);
        return;
      }

      context.read<VerifyBloc>().add(
        VerifySubmitted(email: widget.email, otp: otp),
      );
    }
  }

  void _handleResendOtp() {
    context.read<VerifyBloc>().add(ResendOtpSubmitted(email: widget.email));
  }

  void _handleBackToLogin() {
    context.pushNamedAndRemoveUntil(Routes.login, predicate: (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VerifyBloc, VerifyState>(
      listenWhen: (previous, current) {
        if (current is VerifyDeliveryPending) {
          return previous is! VerifyDeliveryPending;
        }
        if (current is VerifySuccess) {
          return previous is! VerifySuccess;
        }
        if (current is VerifyOtpResent) {
          return previous is! VerifyOtpResent;
        }
        if (current is VerifyError) {
          return previous is! VerifyError;
        }
        return true;
      },
      listener: (context, state) {
        if (state is VerifySuccess) {
          if (state.goToMain) {
            customToast(msg: AppTranslation.accountVerifiedSuccess);
            context.pushNamedAndRemoveUntil(
              Routes.mainNavigation,
              predicate: (route) => false,
            );
          } else {
            customToast(msg: AppTranslation.registerSuccess);
            context.pushNamedAndRemoveUntil(
              Routes.login,
              predicate: (route) => false,
            );
          }
        } else if (state is VerifyDeliveryPending) {
          customToast(msg: AppTranslation.deliveryPendingToast);
          context.pushNamedAndRemoveUntil(
            Routes.deliveryWaiting,
            predicate: (route) => false,
          );
        } else if (state is VerifyOtpResent) {
          customToast(msg: AppTranslation.otpSentSuccess);
        } else if (state is VerifyError) {
          customToast(msg: state.message);
        }
      },
      child: BlocBuilder<VerifyBloc, VerifyState>(
        builder: (context, state) {
          return ModalProgressHUD(
            progressIndicator: const CustomCircleIndicator(),
            inAsyncCall: state is VerifyLoading,
            child: Scaffold(
              backgroundColor: ColorManager.background,
              appBar: CustomAppBar(title: AppTranslation.verifyAccount),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppPadding.p24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VerifyHeader(email: widget.email),
                      VerifyForm(
                        formKey: _formKey,
                        otpController: _otpController,
                        onVerify: _handleVerify,
                        onResendOtp: _handleResendOtp,
                        onBackToLogin: _handleBackToLogin,
                        isLoading: state is VerifyLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

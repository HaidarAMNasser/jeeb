import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_display.dart';
import 'package:jeeb_admin/core/presentation/localization/app_translation.dart';
import 'package:jeeb_admin/core/common/utils/toast_util.dart';
import 'package:jeeb_admin/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_admin/core/presentation/routes/routes.dart';
import '../bloc/verify_bloc.dart';
import '../widgets/verify_header.dart';
import '../widgets/verify_form.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class VerifyPage extends StatefulWidget {
  final String email;

  const VerifyPage({
    super.key,
    required this.email,
  });

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
            VerifySubmitted(
              email: widget.email,
              otp: otp,
            ),
          );
    }
  }

  void _handleResendOtp() {
    context.read<VerifyBloc>().add(
          ResendOtpSubmitted(email: widget.email),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerifyBloc, VerifyState>(
      listener: (context, state) {
        if (state is VerifySuccess) {
          customToast(msg: AppTranslation.accountVerifiedSuccess);
          context.pushNamedAndRemoveUntil(
            Routes.login,
            predicate: (route) => false,
          );
        } else if (state is VerifyOtpResent) {
          customToast(msg: AppTranslation.otpSentSuccess);
        } else if (state is VerifyError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, state) {
        return ModalProgressHUD(
          progressIndicator: const CustomCircleIndicator(),
          inAsyncCall: state is VerifyLoading,
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: AppBar(
              backgroundColor: ColorManager.background,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: ColorManager.titlesColor,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: CustomTextDisplay(
                text: AppTranslation.verifyAccount,
                fontSize: AppFontSize.s24,
                color: ColorManager.titlesColor,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                      isLoading: state is VerifyLoading,
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


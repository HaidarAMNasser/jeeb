import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart'
    show AppTranslation;
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/gradient_text.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/delivery_register_dialog.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool usePhoneLogin;
  final ValueChanged<bool> onLoginMethodChanged;
  final VoidCallback onLogin;
  final VoidCallback onGuestLogin;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.usePhoneLogin,
    required this.onLoginMethodChanged,
    required this.onLogin,
    required this.onGuestLogin,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoginIdentifierField(
            usePhoneLogin: usePhoneLogin,
            onLoginMethodChanged: onLoginMethodChanged,
            emailController: emailController,
            phoneController: phoneController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomTextField(
            obscureText: true,
            showObscureTextToggle: true,
            title: AppTranslation.password,
            hintText: AppTranslation.enterPassword,
            controller: passwordController,
          ),

          SizedBox(height: AppHeight.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextButton(
                  onPressed: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) =>
                          const DeliveryRegisterDialog(),
                    );
                    if (result == 'manual') {
                      context.pushNamed(
                        Routes.register,
                        arguments: {'initialRole': 'DELIVERY'},
                      );
                    }
                  },
                  child: CustomText(
                    text: AppTranslation.joinAsDelivery,
                    textStyle: getMediumStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.primary,
                    ),
                  ),
                ),
              ),
              if (!usePhoneLogin)
                Flexible(
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
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppHeight.s32),
          CustomButton(
            text: AppTranslation.login,
            onPressed: isLoading ? null : onLogin,
            color: ColorManager.primary,
          ),
          SizedBox(height: AppHeight.s16),
          SizedBox(
            height: AppHeight.s56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: isLoading
                    ? null
                    : LinearGradient(
                        colors: [
                          ColorManager.defaultYellow,
                          ColorManager.primary,
                        ],
                      ),
                color: isLoading
                    ? ColorManager.textSecondary.withOpacity(0.4)
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Material(
                  color: ColorManager.background,
                  borderRadius: BorderRadius.circular(AppRadius.r16 - 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.r16 - 2),
                    onTap: isLoading ? null : onGuestLogin,
                    child: Center(
                      child: isLoading
                          ? CustomText(
                              text: AppTranslation.enterAsGuest,
                              textStyle: getBlackStyle(
                                fontSize: AppFontSize.s15,
                                color: ColorManager.textSecondary,
                              ),
                            )
                          : GradientText(
                              text: AppTranslation.enterAsGuest,
                              gradient: LinearGradient(
                                colors: [
                                  ColorManager.defaultYellow,
                                  ColorManager.primary,
                                  ColorManager.primary,
                                ],
                              ),
                              textStyle: TextStyle(
                                fontSize: AppFontSize.s15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppHeight.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                text: AppTranslation.dontHaveAccount,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(Routes.register);
                },
                child: CustomText(
                  text: AppTranslation.register,
                  textStyle: getMediumStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppHeight.s16),
        ],
      ),
    );
  }
}

class _LoginIdentifierField extends StatelessWidget {
  final bool usePhoneLogin;
  final ValueChanged<bool> onLoginMethodChanged;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  const _LoginIdentifierField({
    required this.usePhoneLogin,
    required this.onLoginMethodChanged,
    required this.emailController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (usePhoneLogin)
          CustomTextField(
            keyboardType: TextInputType.phone,
            title: AppTranslation.phone,
            hintText: AppTranslation.enterPhone,
            controller: phoneController,
          )
        else
          CustomTextField(
            title: AppTranslation.email,
            hintText: AppTranslation.enterEmail,
            controller: emailController,
          ),
        SizedBox(height: AppHeight.s8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _LoginMethodSelector(
            usePhoneLogin: usePhoneLogin,
            onChanged: onLoginMethodChanged,
          ),
        ),
      ],
    );
  }
}

class _LoginMethodSelector extends StatelessWidget {
  final bool usePhoneLogin;
  final ValueChanged<bool> onChanged;

  const _LoginMethodSelector({
    required this.usePhoneLogin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _option(
          label: AppTranslation.email,
          selected: !usePhoneLogin,
          onTap: () => onChanged(false),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppWidth.s8),
          child: CustomText(
            text: '·',
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s12,
              color: ColorManager.textSecondary.withOpacity(0.5),
            ),
          ),
        ),
        _option(
          label: AppTranslation.phone,
          selected: usePhoneLogin,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }

  Widget _option({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomText(
        text: label,
        textStyle: selected
            ? getMediumStyle(
                fontSize: AppFontSize.s12,
                color: ColorManager.primary,
              )
            : getRegularStyle(
                fontSize: AppFontSize.s12,
                color: ColorManager.textSecondary,
              ),
      ),
    );
  }
}

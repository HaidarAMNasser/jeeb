import 'package:flutter/material.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/profile/data/repositories/profile_repository.dart';

class DeliveryWaitingPage extends StatefulWidget {
  const DeliveryWaitingPage({super.key});

  @override
  State<DeliveryWaitingPage> createState() => _DeliveryWaitingPageState();
}

class _DeliveryWaitingPageState extends State<DeliveryWaitingPage> {
  bool _isRefreshing = false;

  Future<void> _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    final profileRepository = di.sl<ProfileRepository>();
    final storageService = di.sl<StorageService>();
    final result = await profileRepository.getProfile();

    await result.fold(
      (failure) async {
        customToast(msg: AppTranslation.errorOccurred);
      },
      (user) async {
        if (user.isVerified) {
          await storageService.setLoggedIn(true);
          await storageService.setVerified(true);
          await storageService.setPendingVerifyEmail(null);
          if (!mounted) return;
          context.pushNamedAndRemoveUntil(
            Routes.mainNavigation,
            predicate: (route) => false,
          );
          return;
        }
        customToast(msg: AppTranslation.deliveryPendingToast);
      },
    );

    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
    });
  }

  void _backToLogin() {
    context.pushNamedAndRemoveUntil(Routes.login, predicate: (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.deliveryWaitingTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppPadding.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppHeight.s40),
              Icon(
                Icons.hourglass_top_rounded,
                color: ColorManager.primary,
                size: AppSize.s70,
              ),
              SizedBox(height: AppHeight.s16),
              CustomText(
                text: AppTranslation.deliveryWaitingTitle,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s22,
                  color: ColorManager.titlesColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppHeight.s12),
              CustomText(
                text: AppTranslation.deliveryWaitingSubtitle,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppHeight.s40),
              CustomButton(
                text: AppTranslation.refreshPage,
                onPressed: _isRefreshing ? null : _refreshStatus,
                isLoading: _isRefreshing,
                color: ColorManager.primary,
              ),
              SizedBox(height: AppHeight.s16),
              CustomButton(
                text: AppTranslation.backToLogin,
                onPressed: _backToLogin,
                isOutlined: true,
                color: ColorManager.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../../../../core/common/utils/asset_manager.dart';
import '../../../../core/infrastructure/services/storage_service.dart';
import '../../../../core/infrastructure/di/dependency_injection.dart' as di;
import '../widgets/curved_text_animation.dart';
import '../widgets/shimmer_wave_animation.dart';
import '../../../../core/presentation/routes/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final storage = di.sl<StorageService>();

    final firstLaunch = await storage.isFirstLaunch();
    if (firstLaunch) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.onboarding);
      }
      return;
    }

    final isLoggedIn = await storage.isLoggedIn();
    final isVerified = await storage.isVerified();
    final token = await storage.getUserToken();

    if (isLoggedIn && isVerified && token.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.mainNavigation);
      }
      return;
    }

    final pendingEmail = await storage.getPendingVerifyEmail();
    if (token.isNotEmpty && !isVerified && pendingEmail != null && pendingEmail.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          Routes.verify,
          arguments: {'email': pendingEmail},
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: ShimmerWaveAnimation(
        primaryColor: ColorManager.primary,
        secondaryColor: ColorManager.defaultYellow,
        duration: const Duration(milliseconds: 2000),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: AppHeight.s100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Logo - no animations, just static image
                  Image.asset(
                    ImageAsset.appLogo,
                    width: AppWidth.s100 * 1.5, // Make it bigger (150 instead of 100)
                    height: AppWidth.s100 * 1.5 * 1.5, // Maintain aspect ratio
                    fit: BoxFit.contain,
                  ),
                  // Text animation - letters appear one after another
                  CurvedTextAnimation(
                    text: 'Jeeb',
                    textStyle: getBoldStyle(
                      fontSize: AppFontSize.s50,
                      color: ColorManager.primary,
                    ).copyWith(letterSpacing: 2),
                    curveHeight: AppHeight.s25,
                    letterDelay: const Duration(milliseconds: 300), // Increased delay to make it more visible
                    totalDuration: const Duration(milliseconds: 2000),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),)
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../../../../core/common/utils/asset_manager.dart';
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

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Force LTR direction for splash screen (always in English)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ColorManager.background,
        body: ShimmerWaveAnimation(
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
        ),
      ),
    );
  }
}

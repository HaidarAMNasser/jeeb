import 'package:flutter/material.dart';
import '../../../../core/presentation/routes/routes.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../widgets/curved_text_animation.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupLogoAnimation();
    _navigateToNext();
  }

  void _setupLogoAnimation() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoFadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoController.forward();
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with animation
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Container(
                    width: AppWidth.s100,
                    height: AppWidth.s100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.r24),
                      boxShadow: [
                        BoxShadow(
                          color: ColorManager.primary.withOpacity(0.2),
                          blurRadius: AppSize.s20,
                          offset: Offset(0, AppHeight.s10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(AppPadding.p20),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppHeight.s40),
              // Curved animated text
              CurvedTextAnimation(
                text: 'Jeeb',
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s50,
                  color: ColorManager.primary,
                ).copyWith(letterSpacing: 2),
                curveHeight: AppHeight.s25,
                letterDelay: const Duration(milliseconds: 150),
                totalDuration: const Duration(milliseconds: 2000),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


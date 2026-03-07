import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as el;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/onboarding/presentation/onboarding_strings.dart';
import '../../../../core/presentation/routes/routes.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/widgets/language_selection_dialog.dart';
import '../../../../core/infrastructure/services/storage_service.dart';
import '../../../../core/infrastructure/di/dependency_injection.dart' as di;
import '../bloc/onboarding_bloc.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_bottom_section.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    context.read<OnboardingBloc>().add(const OnboardingInitialized());
  }

  void _navigateToAuth() async {
    // Check if language is set in SharedPreferences
    final storageService = di.sl<StorageService>();
    final storedLanguage = storageService.getAppLanguage();

    // Only show language dialog if language is not set (empty)
    if (storedLanguage.isEmpty) {
      // Show language dialog and wait for selection
      final selectedLanguage = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const LanguageSelectionDialog(),
      );

      if (selectedLanguage != null && mounted) {
        // Save selected language
        await storageService.setAppLanguage(selectedLanguage);

        // Update app locale
        await context.setLocale(Locale(selectedLanguage));
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: SafeArea(
          child: BlocListener<OnboardingBloc, OnboardingState>(
            listener: (context, state) {
              if (state is OnboardingLoaded &&
                  state.notificationPermissionGranted == true) {
                customToast(msg: OnboardingStrings.notificationsEnabledSuccess);
              }
            },
            child: BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (context, state) {
                if (state is OnboardingLoaded) {
                  return Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: state.pages.length,
                          onPageChanged: (index) {
                            context.read<OnboardingBloc>().add(
                              OnboardingPageChanged(index),
                            );
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(top: AppSize.s20.h),
                              child: OnboardingContentWidget(
                                content: state.pages[index],
                                pageIndex: index,
                              ),
                            );
                          },
                        ),
                      ),

                      OnboardingBottomSection(
                        state: state,
                        onGetStarted: _navigateToAuth,
                        onNext: () {
                          context.read<OnboardingBloc>().add(
                            const OnboardingNextPage(),
                          );
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}

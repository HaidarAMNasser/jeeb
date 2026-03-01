import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';
import '../../../../core/presentation/routes/routes.dart';
import '../../../../core/presentation/widgets/text_widget.dart';
import '../../../../core/presentation/localization/app_translation.dart';
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

  void _navigateToAuth() {
    Navigator.pushReplacementNamed(context, Routes.login);
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
      body: SafeArea(
        child: BlocListener<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is OnboardingLoaded &&
                state.notificationPermissionGranted == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: CustomText(
                    text: AppTranslation.notificationsEnabledSuccess,
                  ),
                  backgroundColor: ColorManager.success,
                ),
              );
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
                          return OnboardingContentWidget(
                            content: state.pages[index],
                            pageIndex: index,
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
    );
  }
}

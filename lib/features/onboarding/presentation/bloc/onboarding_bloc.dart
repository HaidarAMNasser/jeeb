import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/common/utils/helper_functions.dart';
import '../onboarding_strings.dart';
import '../widgets/onboarding_content.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingInitial()) {
    on<OnboardingInitialized>(_onInitialized);
    on<OnboardingPageChanged>(_onPageChanged);
    on<OnboardingNextPage>(_onNextPage);
    on<OnboardingSkip>(_onSkip);
    on<OnboardingRequestNotificationPermission>(_onRequestNotificationPermission);
  }

  /// Onboarding content is always in English (never translated to Arabic).
  final List<OnboardingContent> _pages = [
    OnboardingContent(
      title: OnboardingStrings.onboardingTitle1,
      description: OnboardingStrings.onboardingDesc1,
      icon: Icons.restaurant_menu,
      color: ColorManager.defaultYellow,
    ),
    OnboardingContent(
      title: OnboardingStrings.onboardingTitle2,
      description: OnboardingStrings.onboardingDesc2,
      icon: Icons.delivery_dining,
      color: ColorManager.defaultYellow,
    ),
    OnboardingContent(
      title: OnboardingStrings.onboardingTitle3,
      description: OnboardingStrings.onboardingDesc3,
      icon: Icons.notifications_active,
      color: ColorManager.defaultYellow,
    ),
    OnboardingContent(
      title: OnboardingStrings.onboardingTitle4,
      description: OnboardingStrings.onboardingDesc4,
      icon: Icons.celebration,
      color: ColorManager.defaultYellow,
    ),
  ];

  void _onInitialized(
    OnboardingInitialized event,
    Emitter<OnboardingState> emit,
  ) {
    emit(OnboardingLoaded(
      pages: _pages,
      currentPageIndex: 0,
      isLastPage: _pages.length == 1,
    ));
  }

  void _onPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      emit(currentState.copyWith(
        currentPageIndex: event.pageIndex,
      ));
    }
  }

  void _onNextPage(
    OnboardingNextPage event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      final nextIndex = currentState.currentPageIndex + 1;

      if (nextIndex < currentState.pages.length) {
        emit(currentState.copyWith(
          currentPageIndex: nextIndex,
        ));
      }
    }
  }

  void _onSkip(
    OnboardingSkip event,
    Emitter<OnboardingState> emit,
  ) {
    // Skip logic is handled in the UI layer for navigation
    // This event can be used for analytics or other side effects
  }

  Future<void> _onRequestNotificationPermission(
    OnboardingRequestNotificationPermission event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingLoaded) {
      final currentState = state as OnboardingLoaded;
      try {
        final granted = await NotificationPermissionHelper.requestNotificationPermission();
        emit(currentState.copyWith(
          notificationPermissionGranted: granted,
        ));
      } catch (e) {
        // Emit state with false to indicate failure
        emit(currentState.copyWith(
          notificationPermissionGranted: false,
        ));
      }
    }
  }

  List<OnboardingContent> get pages => _pages;
}


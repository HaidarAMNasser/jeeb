part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

class OnboardingInitialized extends OnboardingEvent {
  const OnboardingInitialized();
}

class OnboardingPageChanged extends OnboardingEvent {
  final int pageIndex;

  const OnboardingPageChanged(this.pageIndex);

  @override
  List<Object> get props => [pageIndex];
}

class OnboardingNextPage extends OnboardingEvent {
  const OnboardingNextPage();
}

class OnboardingSkip extends OnboardingEvent {
  const OnboardingSkip();
}

class OnboardingRequestNotificationPermission extends OnboardingEvent {
  const OnboardingRequestNotificationPermission();
}


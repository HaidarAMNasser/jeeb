part of 'onboarding_bloc.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoaded extends OnboardingState {
  final List<OnboardingContent> pages;
  final int currentPageIndex;
  final bool isLastPage;
  final bool? notificationPermissionGranted;

  const OnboardingLoaded({
    required this.pages,
    required this.currentPageIndex,
    required this.isLastPage,
    this.notificationPermissionGranted,
  });

  @override
  List<Object> get props => [
        pages,
        currentPageIndex,
        isLastPage,
        notificationPermissionGranted ?? false,
      ];

  OnboardingLoaded copyWith({
    List<OnboardingContent>? pages,
    int? currentPageIndex,
    bool? isLastPage,
    bool? notificationPermissionGranted,
  }) {
    return OnboardingLoaded(
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isLastPage: isLastPage ?? (currentPageIndex != null
          ? currentPageIndex == (pages ?? this.pages).length - 1
          : this.isLastPage),
      notificationPermissionGranted: notificationPermissionGranted ?? this.notificationPermissionGranted,
    );
  }
}


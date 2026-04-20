part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserEntity user;
  final bool formValuesInitialized;
  final bool updateSuccess;
  final bool isUpdating;
  final Locale? localeToApply;
  /// Set when [UpdateProfile] fails while already loaded; cleared on next update or [ClearProfileUpdateFailure].
  final String? updateFailureMessage;

  const ProfileLoaded({
    required this.user,
    this.formValuesInitialized = false,
    this.updateSuccess = false,
    this.isUpdating = false,
    this.localeToApply,
    this.updateFailureMessage,
  });

  bool get isMerchant => user.role == UserRole.merchant;

  ProfileLoaded copyWith({
    UserEntity? user,
    bool? formValuesInitialized,
    bool? updateSuccess,
    bool? isUpdating,
    Locale? localeToApply,
    String? updateFailureMessage,
    bool clearUpdateFailureMessage = false,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      formValuesInitialized: formValuesInitialized ?? this.formValuesInitialized,
      updateSuccess: updateSuccess ?? this.updateSuccess,
      isUpdating: isUpdating ?? this.isUpdating,
      localeToApply: localeToApply ?? this.localeToApply,
      updateFailureMessage: clearUpdateFailureMessage
          ? null
          : (updateFailureMessage ?? this.updateFailureMessage),
    );
  }

  @override
  List<Object?> get props => [
        user,
        formValuesInitialized,
        updateSuccess,
        isUpdating,
        localeToApply,
        updateFailureMessage,
      ];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object> get props => [message];
}


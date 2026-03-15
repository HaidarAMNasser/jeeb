part of 'get_settings_bloc.dart';

abstract class GetSettingsState extends Equatable {
  const GetSettingsState();

  @override
  List<Object?> get props => [];
}

class GetSettingsInitial extends GetSettingsState {
  const GetSettingsInitial();
}

class GetSettingsLoading extends GetSettingsState {
  const GetSettingsLoading();
}

class GetSettingsLoaded extends GetSettingsState {
  final SettingsEntity settings;

  const GetSettingsLoaded({required this.settings});

  @override
  List<Object?> get props => [settings];
}

class GetSettingsError extends GetSettingsState {
  final String message;

  const GetSettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}

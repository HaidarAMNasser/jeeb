part of 'get_settings_bloc.dart';

abstract class GetSettingsEvent extends Equatable {
  const GetSettingsEvent();

  @override
  List<Object?> get props => [];
}

class GetSettingsRequested extends GetSettingsEvent {
  const GetSettingsRequested();
}

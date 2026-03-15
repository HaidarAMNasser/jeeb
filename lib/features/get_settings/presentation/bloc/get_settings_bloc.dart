import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/get_settings/data/repositories/get_settings_repository.dart';
import 'package:jeeb_app/features/get_settings/domain/entities/settings_entity.dart';

part 'get_settings_event.dart';
part 'get_settings_state.dart';

class GetSettingsBloc extends Bloc<GetSettingsEvent, GetSettingsState> {
  final GetSettingsRepository _repository;

  GetSettingsBloc(this._repository) : super(const GetSettingsInitial()) {
    on<GetSettingsEvent>((event, emit) async {
      if (event is GetSettingsRequested) {
        emit(const GetSettingsLoading());
        final result = await _repository.getSettings();
        result.fold(
          (failure) => emit(GetSettingsError(message: failure.message)),
          (settings) => emit(GetSettingsLoaded(settings: settings)),
        );
      }
    });
  }
}

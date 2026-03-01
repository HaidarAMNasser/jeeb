import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/auth/domain/entities/user_entity.dart';
import 'package:jeeb_app/features/auth/profile/data/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(const ProfileInitial()) {
    on<ProfileEvent>(_onEvent);
  }

  Future<void> _onEvent(
      ProfileEvent event, Emitter<ProfileState> emit) async {
    if (event is GetProfile) {
      emit(const ProfileLoading());
      final result = await _repository.getProfile();
      result.fold(
        (f) => emit(ProfileError(message: f.message)),
        (user) => emit(ProfileLoaded(user: user)),
      );
    } else if (event is UpdateProfile) {
      emit(const ProfileLoading());
      final result = await _repository.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        countryId: event.countryId,
        cityId: event.cityId,
        address: event.address,
      );
      result.fold(
        (f) => emit(ProfileError(message: f.message)),
        (user) => emit(ProfileUpdated(user: user)),
      );
    }
  }
}

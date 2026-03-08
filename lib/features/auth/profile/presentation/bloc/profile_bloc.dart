import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../login/domain/entities/user_entity.dart';
import '../../data/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc(this._profileRepository) : super(const ProfileInitial()) {
    on<ProfileEvent>((event, emit) async {
      if (event is GetProfile) {
        emit(const ProfileLoading());
        final result = await _profileRepository.getProfile();

        result.fold(
          (failure) => emit(ProfileError(message: failure.message)),
          (user) => emit(ProfileLoaded(user: user)),
        );
      } else if (event is UpdateProfile) {
        emit(const ProfileLoading());
        final result = await _profileRepository.updateProfile(
          firstName: event.firstName,
          lastName: event.lastName,
          phone: event.phone,
          countryId: event.countryId,
          cityId: event.cityId,
          address: event.address,
        );

        result.fold(
          (failure) => emit(ProfileError(message: failure.message)),
          (user) => emit(ProfileLoaded(user: user)),
        );
      }
    });
  }
}
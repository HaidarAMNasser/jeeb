import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import '../../../login/domain/entities/user_entity.dart';
import '../../data/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final StorageService _storageService;

  ProfileBloc(this._profileRepository, this._storageService) : super(const ProfileInitial()) {
    on<ProfileEvent>((event, emit) async {
      if (event is GetProfile) {
        emit(const ProfileLoading());
        final result = await _profileRepository.getProfile();

        result.fold(
          (failure) => emit(ProfileError(message: failure.message)),
          (user) => emit(ProfileLoaded(user: user, updateSuccess: false)),
        );
      } else if (event is UpdateProfile) {
        final current = state;
        final ProfileLoaded? previous =
            current is ProfileLoaded ? current : null;
        final hadUser = previous != null;
        if (hadUser) {
          if (!emit.isDone) {
            emit(
              previous.copyWith(
                isUpdating: true,
                clearUpdateFailureMessage: true,
              ),
            );
          }
        } else {
          emit(const ProfileLoading());
        }
        final result = await _profileRepository.updateProfile(
          firstName: event.firstName,
          lastName: event.lastName,
          phone: event.phone,
          countryId: event.countryId,
          cityId: event.cityId,
          address: event.address,
          latitude: event.latitude,
          longitude: event.longitude,
          isActive: event.isActive,
          imageFile: event.imageFile,
          password: event.password,
          newPassword: event.newPassword,
          confirmedPassword: event.confirmedPassword,
        );

        await result.fold(
          (failure) async {
            if (!emit.isDone) {
              if (hadUser) {
                emit(
                  previous.copyWith(
                    isUpdating: false,
                    updateFailureMessage: failure.message,
                  ),
                );
              } else {
                emit(ProfileError(message: failure.message));
              }
            }
          },
          (user) async {
            if (!emit.isDone) {
              emit(ProfileLoaded(
                user: user,
                formValuesInitialized: hadUser
                    ? previous.formValuesInitialized
                    : false,
                updateSuccess: true,
                isUpdating: false,
                localeToApply: hadUser ? previous.localeToApply : null,
              ));
            }
          },
        );
      } else if (event is FormValuesInitialized) {
        final current = state;
        if (current is ProfileLoaded && !current.formValuesInitialized) {
          if (!emit.isDone) emit(current.copyWith(formValuesInitialized: true));
        }
      } else if (event is ClearUpdateSuccess) {
        final current = state;
        if (current is ProfileLoaded && current.updateSuccess) {
          if (!emit.isDone) emit(current.copyWith(updateSuccess: false));
        }
      } else if (event is ClearProfileUpdateFailure) {
        final current = state;
        if (current is ProfileLoaded && current.updateFailureMessage != null) {
          if (!emit.isDone) {
            emit(current.copyWith(clearUpdateFailureMessage: true));
          }
        }
      } else if (event is SaveProfile) {
        final firstName = event.firstName.trim();
        final lastName = event.lastName.trim();
        if (firstName.isEmpty || lastName.isEmpty) {
          if (!emit.isDone) emit(const ProfileError(message: 'First and last name are required'));
          return;
        }
        add(UpdateProfile(
          firstName: firstName,
          lastName: lastName,
          phone: event.phone.trim(),
          address: event.address?.trim().isEmpty ?? true ? null : event.address?.trim(),
        ));
      } else if (event is ChangeLanguage) {
        await _storageService.setAppLanguage(event.languageCode);
        final current = state;
        if (current is ProfileLoaded && !emit.isDone) {
          emit(current.copyWith(localeToApply: Locale(event.languageCode)));
        }
      } else if (event is ClearLocaleToApply) {
        final current = state;
        if (current is ProfileLoaded && current.localeToApply != null && !emit.isDone) {
          emit(ProfileLoaded(
            user: current.user,
            formValuesInitialized: current.formValuesInitialized,
            updateSuccess: current.updateSuccess,
            isUpdating: current.isUpdating,
            updateFailureMessage: current.updateFailureMessage,
          ));
        }
      } else if (event is UpdateLocation) {
        add(UpdateProfile(latitude: event.latitude, longitude: event.longitude));
      } else if (event is UpdateAccountActive) {
        add(UpdateProfile(isActive: event.isActive));
      }
    });
  }
}


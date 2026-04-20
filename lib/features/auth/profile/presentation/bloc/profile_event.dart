part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class GetProfile extends ProfileEvent {
  const GetProfile();
}

class UpdateProfile extends ProfileEvent {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final int? countryId;
  final int? cityId;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool? isActive;
  final dynamic imageFile;
  final String? password;
  final String? newPassword;
  final String? confirmedPassword;

  const UpdateProfile({
    this.firstName,
    this.lastName,
    this.phone,
    this.countryId,
    this.cityId,
    this.address,
    this.latitude,
    this.longitude,
    this.isActive,
    this.imageFile,
    this.password,
    this.newPassword,
    this.confirmedPassword,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        countryId,
        cityId,
        address,
        latitude,
        longitude,
        isActive,
        imageFile,
        password,
        newPassword,
        confirmedPassword,
      ];
}

class FormValuesInitialized extends ProfileEvent {
  const FormValuesInitialized();
}

class ClearUpdateSuccess extends ProfileEvent {
  const ClearUpdateSuccess();
}

class ClearProfileUpdateFailure extends ProfileEvent {
  const ClearProfileUpdateFailure();
}

class SaveProfile extends ProfileEvent {
  final String firstName;
  final String lastName;
  final String phone;
  final String? address;

  const SaveProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.address,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone, address];
}

class ChangeLanguage extends ProfileEvent {
  final String languageCode;

  const ChangeLanguage(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class ClearLocaleToApply extends ProfileEvent {
  const ClearLocaleToApply();
}

class UpdateLocation extends ProfileEvent {
  final double latitude;
  final double longitude;

  const UpdateLocation({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class UpdateAccountActive extends ProfileEvent {
  final bool isActive;

  const UpdateAccountActive(this.isActive);

  @override
  List<Object?> get props => [isActive];
}


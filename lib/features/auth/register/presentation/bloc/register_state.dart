part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  final CountryEntity? selectedCountry;
  final CityEntity? selectedCity;
  final bool isLocationLoading;
  final double? useLocationLat;
  final double? useLocationLng;
  final String? locationDisplayCountry;
  final String? locationDisplayCity;
  final String? locationDisplayStreet;

  const RegisterState({
    this.selectedCountry,
    this.selectedCity,
    this.isLocationLoading = false,
    this.useLocationLat,
    this.useLocationLng,
    this.locationDisplayCountry,
    this.locationDisplayCity,
    this.locationDisplayStreet,
  });

  @override
  List<Object?> get props => [
        selectedCountry,
        selectedCity,
        isLocationLoading,
        useLocationLat,
        useLocationLng,
        locationDisplayCountry,
        locationDisplayCity,
        locationDisplayStreet,
      ];
}

class RegisterInitial extends RegisterState {
  const RegisterInitial({
    super.selectedCountry,
    super.selectedCity,
    super.isLocationLoading,
    super.useLocationLat,
    super.useLocationLng,
    super.locationDisplayCountry,
    super.locationDisplayCity,
    super.locationDisplayStreet,
  });
}

class RegisterLoading extends RegisterState {
  const RegisterLoading({
    super.selectedCountry,
    super.selectedCity,
    super.isLocationLoading,
    super.useLocationLat,
    super.useLocationLng,
    super.locationDisplayCountry,
    super.locationDisplayCity,
    super.locationDisplayStreet,
  });
}

class RegisterSuccess extends RegisterState {
  final int userId;
  final String email;

  const RegisterSuccess({
    required this.userId,
    required this.email,
    super.selectedCountry,
    super.selectedCity,
    super.isLocationLoading,
    super.useLocationLat,
    super.useLocationLng,
    super.locationDisplayCountry,
    super.locationDisplayCity,
    super.locationDisplayStreet,
  });

  @override
  List<Object?> get props => [...super.props, userId, email];
}

class RegisterError extends RegisterState {
  final String message;

  const RegisterError({
    required this.message,
    super.selectedCountry,
    super.selectedCity,
    super.isLocationLoading,
    super.useLocationLat,
    super.useLocationLng,
    super.locationDisplayCountry,
    super.locationDisplayCity,
    super.locationDisplayStreet,
  });

  @override
  List<Object?> get props => [...super.props, message];
}


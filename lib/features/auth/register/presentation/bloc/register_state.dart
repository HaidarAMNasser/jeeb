part of 'register_bloc.dart';

abstract class RegisterState extends Equatable {
  final CountryEntity? selectedCountry;
  final CityEntity? selectedCity;
  final bool isLocationLoading;
  final double? useLocationLat;
  final double? useLocationLng;

  const RegisterState({
    this.selectedCountry,
    this.selectedCity,
    this.isLocationLoading = false,
    this.useLocationLat,
    this.useLocationLng,
  });

  @override
  List<Object?> get props => [
        selectedCountry,
        selectedCity,
        isLocationLoading,
        useLocationLat,
        useLocationLng,
      ];
}

class RegisterInitial extends RegisterState {
  const RegisterInitial({
    super.selectedCountry,
    super.selectedCity,
    super.isLocationLoading,
    super.useLocationLat,
    super.useLocationLng,
  });
}

class RegisterLoading extends RegisterState {
  const RegisterLoading({
    super.selectedCountry,
    super.selectedCity,
    super.isLocationLoading,
    super.useLocationLat,
    super.useLocationLng,
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
  });

  @override
  List<Object?> get props => [...super.props, message];
}


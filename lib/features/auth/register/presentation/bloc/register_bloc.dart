import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';
import '../../../../../core/infrastructure/services/storage_service.dart'
    show StorageService;
import '../../data/repositories/register_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterRepository _registerRepository;
  final StorageService _storageService;
  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final birthdayController = TextEditingController();

  String? selectedRole = 'CUSTOMER';
  String selectedNotificationChannel = 'EMAIL';
  CountryEntity? selectedCountry;
  CityEntity? selectedCity;
  bool isLocationLoading = false;
  double? useLocationLat;
  double? useLocationLng;
  dynamic selectedImageFile;
  dynamic idFrontImageFile;
  dynamic idBackImageFile;
  int _imageVersion = 0;
  int get imageVersion => _imageVersion;
  int _idFrontVersion = 0;
  int get idFrontVersion => _idFrontVersion;
  int _idBackVersion = 0;
  int get idBackVersion => _idBackVersion;

  RegisterBloc(this._registerRepository, this._storageService)
    : super(const RegisterInitial()) {
    on<RegisterCountryChanged>((event, emit) {
      selectedCountry = event.country;
      selectedCity = null;
      emit(_buildInitialState());
    });

    on<RegisterCityChanged>((event, emit) {
      selectedCity = event.city;
      emit(_buildInitialState());
    });

    on<RegisterRoleChanged>((event, emit) {
      selectedRole = event.role;
      emit(_buildInitialState());
    });

    on<RegisterImageChanged>((event, emit) {
      _imageVersion++;
      selectedImageFile = event.imageFile;
      emit(_buildInitialState());
    });

    on<RegisterIdFrontChanged>((event, emit) {
      _idFrontVersion++;
      idFrontImageFile = event.imageFile;
      emit(_buildInitialState());
    });

    on<RegisterIdBackChanged>((event, emit) {
      _idBackVersion++;
      idBackImageFile = event.imageFile;
      emit(_buildInitialState());
    });

    on<RegisterNotificationChannelChanged>((event, emit) {
      selectedNotificationChannel = event.channel;
      emit(_buildInitialState());
    });

    on<RegisterLocationLoadingChanged>((event, emit) {
      isLocationLoading = event.isLoading;
      emit(_buildInitialState());
    });

    on<RegisterLocationUpdated>((event, emit) {
      useLocationLat = event.latitude;
      useLocationLng = event.longitude;
      emit(_buildInitialState());
    });

    on<RegisterLocationCleared>((event, emit) {
      useLocationLat = null;
      useLocationLng = null;
      emit(_buildInitialState());
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(_buildLoadingState());

      final result = await _registerRepository.register(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        role: selectedRole ?? 'CUSTOMER',
        countryId: selectedCountry?.id,
        cityId: selectedCity?.id,
        latitude: useLocationLat,
        longitude: useLocationLng,
        notificationChannel: selectedNotificationChannel,
        address: addressController.text.trim(),
        birthday: birthdayController.text.trim().isEmpty
            ? null
            : birthdayController.text.trim(),
        imageFile: (selectedRole == 'DELIVERY') ? null : selectedImageFile,
        idFrontFile: idFrontImageFile,
        idBackFile: idBackImageFile,
      );

      await result.fold(
        (failure) async => emit(
          RegisterError(
            message: failure.message,
            selectedCountry: selectedCountry,
            selectedCity: selectedCity,
            isLocationLoading: isLocationLoading,
            useLocationLat: useLocationLat,
            useLocationLng: useLocationLng,
          ),
        ),
        (tokenEntity) async {
          if (tokenEntity != null) {
            await _storageService.setUserToken(tokenEntity.accessToken);
            await _storageService.setUserId(tokenEntity.user.id);
            await _storageService.setUserRole(tokenEntity.user.role.name);
            await _storageService.setPendingVerifyEmail(
              emailController.text.trim(),
            );
          }
          if (!emit.isDone) {
            emit(
              RegisterSuccess(
                userId: tokenEntity?.user.id ?? 0,
                email: emailController.text.trim(),
                selectedCountry: selectedCountry,
                selectedCity: selectedCity,
                isLocationLoading: isLocationLoading,
                useLocationLat: useLocationLat,
                useLocationLng: useLocationLng,
              ),
            );
          }
        },
      );
    });
  }

  RegisterInitial _buildInitialState() {
    return RegisterInitial(
      selectedCountry: selectedCountry,
      selectedCity: selectedCity,
      isLocationLoading: isLocationLoading,
      useLocationLat: useLocationLat,
      useLocationLng: useLocationLng,
    );
  }

  RegisterLoading _buildLoadingState() {
    return RegisterLoading(
      selectedCountry: selectedCountry,
      selectedCity: selectedCity,
      isLocationLoading: isLocationLoading,
      useLocationLat: useLocationLat,
      useLocationLng: useLocationLng,
    );
  }

  @override
  Future<void> close() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    birthdayController.dispose();
    return super.close();
  }
}

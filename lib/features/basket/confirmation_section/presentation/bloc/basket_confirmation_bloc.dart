import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/address_geocoding.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_service.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/features/auth/profile/data/repositories/profile_repository.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket_order_location_session.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_event.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_state.dart';
import 'package:jeeb_app/features/delivery/order/create_order/data/repositories/create_order_repository.dart';
import 'package:jeeb_app/features/delivery/order/create_order/domain/entities/create_order_params.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/domain/entities/order_before_confirm_preview.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class BasketConfirmationBloc
    extends Bloc<BasketConfirmationEvent, BasketConfirmationState> {
  final CreateOrderRepository _orderRepository;
  final ProfileRepository _profileRepository;
  final NavigationService _navigationService;

  BasketConfirmationBloc({
    required List<ConfirmationItem> items,
    required String merchantName,
    required String? merchantOwnerId,
    required double latitude,
    required double longitude,
    required String initialPhone,
    required CreateOrderRepository orderRepository,
    required ProfileRepository profileRepository,
    required NavigationService navigationService,
    OrderBeforeConfirmPreview? deliveryPreview,
  }) : _orderRepository = orderRepository,
       _profileRepository = profileRepository,
       _navigationService = navigationService,
       super(
         BasketConfirmationState.initial(
           items: items,
           merchantName: merchantName,
           merchantOwnerId: merchantOwnerId,
           latitude: latitude,
           longitude: longitude,
           initialPhone: initialPhone,
           deliveryPreview: deliveryPreview,
         ),
       ) {
    on<BasketConfirmationStarted>(_onStarted);
    on<BasketConfirmationNameChanged>(_onNameChanged);
    on<BasketConfirmationStreetChanged>(_onStreetChanged);
    on<BasketConfirmationAddressDetailsChanged>(_onAddressDetailsChanged);
    on<BasketConfirmationPhoneChanged>(_onPhoneChanged);
    on<BasketConfirmationLocationPicked>(_onLocationPicked);
    on<BasketConfirmationAreaChanged>(_onAreaChanged);
    on<BasketConfirmationSubmitRequested>(_onSubmitRequested);
    on<BasketConfirmationFieldSyncConsumed>(_onFieldSyncConsumed);
    on<BasketConfirmationSuccessHandled>(_onSuccessHandled);

    add(const BasketConfirmationStarted());
  }

  void _showSnackBar(String message) {
    final ctx = _navigationService.navigationKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  void _emitSubmitError(String message, Emitter<BasketConfirmationState> emit) {
    emit(state.copyWith(isSubmitting: false, submitError: message));
    _showSnackBar(message);
    emit(state.copyWith(clearSubmitError: true));
  }

  void _navigateAfterOrderSuccess(String orderId) {
    _navigationService.back();
    _navigationService.pushNamed(
      Routes.orderStatus,
      arguments: {
        'orderId': orderId,
        'initialStatus': OrderStatus.pending.apiWireValue,
        'deliveryLatitude': state.latitude,
        'deliveryLongitude': state.longitude,
      },
    );
  }

  Future<void> _onStarted(
    BasketConfirmationStarted event,
    Emitter<BasketConfirmationState> emit,
  ) async {
    emit(state.copyWith(isResolvingAddress: true));

    final profileResult = await _profileRepository.getProfile();
    final resolved = await AddressGeocoding.fromCoordinates(
      latitude: state.latitude,
      longitude: state.longitude,
    );
    if (isClosed) return;

    final s = state;
    var newName = s.name;
    var newPhone = s.phone;
    var profileCityId = s.profileCityId;

    profileResult.fold((_) {}, (user) {
      newName = s.name.trim().isEmpty ? user.fullName.trim() : s.name;
      newPhone = s.phone.trim().isEmpty ? user.phone.trim() : s.phone;
      profileCityId = user.cityId > 0 ? user.cityId : s.profileCityId;
    });

    emit(
      s.copyWith(
        name: newName,
        phone: newPhone,
        profileCityId: profileCityId,
        country: resolved?.country,
        city: resolved?.city,
        street: resolved?.street ?? '',
        isResolvingAddress: false,
        locationVersion: s.locationVersion + 1,
        pendingFieldSync: BasketConfirmationFieldSync.initialSync,
      ),
    );
  }

  void _onFieldSyncConsumed(
    BasketConfirmationFieldSyncConsumed event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(pendingFieldSync: BasketConfirmationFieldSync.none));
  }

  void _onSuccessHandled(
    BasketConfirmationSuccessHandled event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(clearCreatedOrderId: true));
  }

  Future<void> _resolveAddressAfterLocationChange(
    Emitter<BasketConfirmationState> emit,
  ) async {
    emit(state.copyWith(isResolvingAddress: true));
    final lat = state.latitude;
    final lng = state.longitude;
    final resolved = await AddressGeocoding.fromCoordinates(
      latitude: lat,
      longitude: lng,
    );
    if (isClosed) return;
    emit(
      state.copyWith(
        country: resolved?.country,
        city: resolved?.city,
        street: resolved?.street ?? '',
        isResolvingAddress: false,
        locationVersion: state.locationVersion + 1,
        pendingFieldSync: BasketConfirmationFieldSync.streetOnly,
      ),
    );
  }

  void _onNameChanged(
    BasketConfirmationNameChanged event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onStreetChanged(
    BasketConfirmationStreetChanged event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(street: event.street));
  }

  void _onAddressDetailsChanged(
    BasketConfirmationAddressDetailsChanged event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(addressDetails: event.addressDetails));
  }

  void _onPhoneChanged(
    BasketConfirmationPhoneChanged event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(phone: event.phone));
  }

  void _onAreaChanged(
    BasketConfirmationAreaChanged event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(selectedArea: event.area));
  }

  Future<void> _onLocationPicked(
    BasketConfirmationLocationPicked event,
    Emitter<BasketConfirmationState> emit,
  ) async {
    BasketOrderLocationSession.save(event.latitude, event.longitude);
    emit(
      state.copyWith(
        latitude: event.latitude,
        longitude: event.longitude,
        clearSubmitError: true,
      ),
    );
    await _resolveAddressAfterLocationChange(emit);
  }

  Future<void> _onSubmitRequested(
    BasketConfirmationSubmitRequested event,
    Emitter<BasketConfirmationState> emit,
  ) async {
    final s = state;
    if (s.isResolvingAddress) {
      _emitSubmitError(AppTranslation.basketConfirmWaitAddress, emit);
      return;
    }
    if (s.name.trim().isEmpty) {
      _emitSubmitError(AppTranslation.pleaseEnterFullName, emit);
      return;
    }
    if (s.street.trim().isEmpty) {
      _emitSubmitError(AppTranslation.pleaseEnterStreet, emit);
      return;
    }
    if (s.addressDetails.trim().isEmpty) {
      _emitSubmitError(AppTranslation.pleaseEnterAddressDetails, emit);
      return;
    }
    final ownerId = int.tryParse(s.merchantOwnerId ?? '');
    if (ownerId == null) {
      _emitSubmitError(AppTranslation.orderOwnerRequired, emit);
      return;
    }

    final products = <CreateOrderProductLine>[];
    final offers = <CreateOrderOfferLine>[];
    for (final item in s.items) {
      final id = int.tryParse(item.productId);
      if (id == null) continue;
      if (item.isOffer) {
        offers.add(CreateOrderOfferLine(offerId: id, quantity: item.quantity));
      } else {
        products.add(
          CreateOrderProductLine(productId: id, quantity: item.quantity),
        );
      }
    }

    if (products.isEmpty && offers.isEmpty) {
      _emitSubmitError(AppTranslation.orderItemsInvalid, emit);
      return;
    }

    final phone = s.phone.trim();
    if (phone.isEmpty) {
      _emitSubmitError(AppTranslation.pleaseEnterPhone, emit);
      return;
    }

    final street = s.street.trim();
    final extra = s.addressDetails.trim();
    final primaryAddress = street.isNotEmpty
        ? street
        : (extra.isNotEmpty ? extra : null);
    final landmark = s.city?.trim();
    final landmarkValue = landmark != null && landmark.isNotEmpty
        ? landmark
        : null;

    final areaId = int.tryParse(s.selectedArea?.id ?? '');
    if (areaId == null || areaId < 1) {
      _emitSubmitError(AppTranslation.pleaseSelectArea, emit);
      return;
    }

    final params = CreateOrderParams(
      ownerId: ownerId,
      products: products,
      offers: offers,
      delivery: CreateOrderDeliveryCoordinates(
        latitude: s.latitude,
        longitude: s.longitude,
        address: primaryAddress,
        landmark: landmarkValue,
        specialInstructions: extra.isNotEmpty ? extra : null,
      ),
      tipAmount: 0,
      areaId: areaId,
      customerName: s.name.trim(),
      customerPhone: phone,
    );

    emit(s.copyWith(isSubmitting: true, clearSubmitError: true));
    final result = await _orderRepository.createOrder(params);
    if (isClosed) return;
    result.fold((failure) => _emitSubmitError(failure.message, emit), (
      orderId,
    ) {
      emit(state.copyWith(isSubmitting: false, createdOrderId: orderId));
      _navigateAfterOrderSuccess(orderId);
    });
  }
}

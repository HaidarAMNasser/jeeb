import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/address_geocoding.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/auth/profile/data/repositories/profile_repository.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket_order_location_session.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_event.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_state.dart';
import 'package:jeeb_app/features/order/create_order/data/repositories/create_order_repository.dart';
import 'package:jeeb_app/features/order/create_order/domain/entities/create_order_params.dart';

class BasketConfirmationBloc
    extends Bloc<BasketConfirmationEvent, BasketConfirmationState> {
  final CreateOrderRepository _orderRepository;
  final ProfileRepository _profileRepository;

  BasketConfirmationBloc({
    required List<ConfirmationItem> items,
    required String merchantName,
    required String? merchantOwnerId,
    required double latitude,
    required double longitude,
    required String initialPhone,
    required CreateOrderRepository orderRepository,
    required ProfileRepository profileRepository,
  })  : _orderRepository = orderRepository,
        _profileRepository = profileRepository,
        super(
          BasketConfirmationState.initial(
            items: items,
            merchantName: merchantName,
            merchantOwnerId: merchantOwnerId,
            latitude: latitude,
            longitude: longitude,
            initialPhone: initialPhone,
          ),
        ) {
    on<BasketConfirmationStarted>(_onStarted);
    on<BasketConfirmationNameChanged>(_onNameChanged);
    on<BasketConfirmationStreetChanged>(_onStreetChanged);
    on<BasketConfirmationAddressDetailsChanged>(_onAddressDetailsChanged);
    on<BasketConfirmationPhoneChanged>(_onPhoneChanged);
    on<BasketConfirmationLocationPicked>(_onLocationPicked);
    on<BasketConfirmationSubmitRequested>(_onSubmitRequested);
    on<BasketConfirmationSubmitErrorCleared>(_onSubmitErrorCleared);

    add(const BasketConfirmationStarted());
  }

  Future<void> _onStarted(
    BasketConfirmationStarted event,
    Emitter<BasketConfirmationState> emit,
  ) async {
    await Future.wait([
      _loadProfile(emit),
      _resolveAddress(emit),
    ]);
  }

  Future<void> _loadProfile(Emitter<BasketConfirmationState> emit) async {
    final result = await _profileRepository.getProfile();
    if (isClosed) return;
    result.fold((_) {}, (user) {
      if (isClosed) return;
      final s = state;
      emit(
        s.copyWith(
          name: s.name.trim().isEmpty ? user.fullName.trim() : s.name,
          phone: s.phone.trim().isEmpty ? user.phone.trim() : s.phone,
          profileCityId: user.cityId > 0 ? user.cityId : s.profileCityId,
        ),
      );
    });
  }

  Future<void> _resolveAddress(Emitter<BasketConfirmationState> emit) async {
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
    await _resolveAddress(emit);
  }

  Future<void> _onSubmitRequested(
    BasketConfirmationSubmitRequested event,
    Emitter<BasketConfirmationState> emit,
  ) async {
    final s = state;
    final ownerId = int.tryParse(s.merchantOwnerId ?? '');
    if (ownerId == null) {
      emit(s.copyWith(submitError: AppTranslation.orderOwnerRequired));
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
      emit(s.copyWith(submitError: AppTranslation.orderItemsInvalid));
      return;
    }

    final phone = s.phone.trim();
    if (phone.isEmpty) {
      emit(s.copyWith(submitError: AppTranslation.pleaseEnterPhone));
      return;
    }

    final street = s.street.trim();
    final extra = s.addressDetails.trim();
    final primaryAddress = street.isNotEmpty
        ? street
        : (extra.isNotEmpty ? extra : null);
    final landmark = s.city?.trim();
    final landmarkValue =
        landmark != null && landmark.isNotEmpty ? landmark : null;

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
      cityId: s.profileCityId,
      customerName: s.name.trim().isNotEmpty ? s.name.trim() : null,
      customerPhone: phone,
    );

    emit(s.copyWith(isSubmitting: true, clearSubmitError: true));
    final result = await _orderRepository.createOrder(params);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          submitError: failure.message,
        ),
      ),
      (orderId) => emit(
        state.copyWith(
          isSubmitting: false,
          orderIdSuccess: orderId,
        ),
      ),
    );
  }

  void _onSubmitErrorCleared(
    BasketConfirmationSubmitErrorCleared event,
    Emitter<BasketConfirmationState> emit,
  ) {
    emit(state.copyWith(clearSubmitError: true));
  }
}

import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/confirmation_item.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/domain/entities/order_before_confirm_preview.dart';

/// Tells the UI to copy [BasketConfirmationState] into text controllers once.
enum BasketConfirmationFieldSync {
  none,
  /// First load: profile + reverse geocode applied together.
  initialSync,
  /// New coordinates / geocode (street line only).
  streetOnly,
}

class BasketConfirmationState extends Equatable {
  final List<ConfirmationItem> items;
  final String merchantName;
  final String? merchantOwnerId;
  final double latitude;
  final double longitude;
  final String? country;
  final String? city;
  final bool isResolvingAddress;
  final String name;
  final String street;
  final String addressDetails;
  final String phone;
  final int? profileCityId;
  final int locationVersion;
  final bool isSubmitting;
  final String? submitError;
  final String? createdOrderId;
  final BasketConfirmationFieldSync pendingFieldSync;
  final OrderBeforeConfirmPreview? deliveryPreview;

  const BasketConfirmationState({
    required this.items,
    required this.merchantName,
    required this.merchantOwnerId,
    required this.latitude,
    required this.longitude,
    this.country,
    this.city,
    required this.isResolvingAddress,
    required this.name,
    required this.street,
    required this.addressDetails,
    required this.phone,
    this.profileCityId,
    required this.locationVersion,
    required this.isSubmitting,
    this.submitError,
    this.createdOrderId,
    this.pendingFieldSync = BasketConfirmationFieldSync.none,
    this.deliveryPreview,
  });

  factory BasketConfirmationState.initial({
    required List<ConfirmationItem> items,
    required String merchantName,
    required String? merchantOwnerId,
    required double latitude,
    required double longitude,
    required String initialPhone,
    OrderBeforeConfirmPreview? deliveryPreview,
  }) {
    return BasketConfirmationState(
      items: items,
      merchantName: merchantName,
      merchantOwnerId: merchantOwnerId,
      latitude: latitude,
      longitude: longitude,
      isResolvingAddress: true,
      name: '',
      street: '',
      addressDetails: '',
      phone: initialPhone,
      locationVersion: 0,
      isSubmitting: false,
      deliveryPreview: deliveryPreview,
    );
  }

  BasketConfirmationState copyWith({
    List<ConfirmationItem>? items,
    String? merchantName,
    String? merchantOwnerId,
    double? latitude,
    double? longitude,
    String? country,
    String? city,
    bool? isResolvingAddress,
    String? name,
    String? street,
    String? addressDetails,
    String? phone,
    int? profileCityId,
    int? locationVersion,
    bool? isSubmitting,
    String? submitError,
    String? createdOrderId,
    BasketConfirmationFieldSync? pendingFieldSync,
    OrderBeforeConfirmPreview? deliveryPreview,
    bool clearSubmitError = false,
    bool clearCreatedOrderId = false,
  }) {
    return BasketConfirmationState(
      items: items ?? this.items,
      merchantName: merchantName ?? this.merchantName,
      merchantOwnerId: merchantOwnerId ?? this.merchantOwnerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      country: country ?? this.country,
      city: city ?? this.city,
      isResolvingAddress: isResolvingAddress ?? this.isResolvingAddress,
      name: name ?? this.name,
      street: street ?? this.street,
      addressDetails: addressDetails ?? this.addressDetails,
      phone: phone ?? this.phone,
      profileCityId: profileCityId ?? this.profileCityId,
      locationVersion: locationVersion ?? this.locationVersion,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      createdOrderId: clearCreatedOrderId
          ? null
          : (createdOrderId ?? this.createdOrderId),
      pendingFieldSync: pendingFieldSync ?? this.pendingFieldSync,
      deliveryPreview: deliveryPreview ?? this.deliveryPreview,
    );
  }

  /// Profile + reverse geocode (or post–map-pick geocode) has finished.
  bool get isAddressDataReady => !isResolvingAddress;

  bool get hasAllRequiredFormFields =>
      name.trim().isNotEmpty &&
      street.trim().isNotEmpty &&
      addressDetails.trim().isNotEmpty &&
      phone.trim().isNotEmpty;

  bool get canSubmitOrder =>
      isAddressDataReady && hasAllRequiredFormFields && !isSubmitting;

  @override
  List<Object?> get props => [
        items,
        merchantName,
        merchantOwnerId,
        latitude,
        longitude,
        country,
        city,
        isResolvingAddress,
        name,
        street,
        addressDetails,
        phone,
        profileCityId,
        locationVersion,
        isSubmitting,
        submitError,
        createdOrderId,
        pendingFieldSync,
        deliveryPreview,
      ];
}

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';

/// Map markers for [DeliveryHomePage] (assigned order legs + available orders).
Set<Marker> buildDeliveryHomeMapMarkers(
  DeliveryHomeState state, {
  BitmapDescriptor? pickupMarkerIcon,
  BitmapDescriptor? dropoffMarkerIcon,
}) {
  if (state is! DeliveryHomeLoaded) return {};
  final markers = <Marker>{};

  if (state.assignedOrder != null) {
    final o = state.assignedOrder!;
    final restaurantName = o.owner?.restaurantName?.trim().isNotEmpty == true
        ? o.owner!.restaurantName!
        : AppTranslation.restaurantName;
    final rLat = o.restaurantLatitude;
    final rLng = o.restaurantLongitude;
    final dLat = o.dropoffLatitude;
    final dLng = o.dropoffLongitude;

    if (rLat != null && rLng != null) {
      markers.add(
        Marker(
          markerId: MarkerId('pickup_${o.id}'),
          position: LatLng(rLat, rLng),
          icon: pickupMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: restaurantName,
            snippet: o.owner?.address ?? o.pickupAddress,
          ),
        ),
      );
    }
    if (dLat != null && dLng != null) {
      markers.add(
        Marker(
          markerId: MarkerId('dropoff_${o.id}'),
          position: LatLng(dLat, dLng),
          icon: dropoffMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: o.displayCustomerName ?? AppTranslation.customer,
            snippet: o.displayCustomerAddressLine ??
                o.deliveryAddress ??
                o.customer?.address,
          ),
        ),
      );
    }
    if ((rLat == null || rLng == null || dLat == null || dLng == null) &&
        o.latitude != null &&
        o.longitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId('order_${o.id}'),
          position: LatLng(o.latitude!, o.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: o.displayCustomerName ?? AppTranslation.customer,
          ),
        ),
      );
    }
  }

  for (final o in state.availableOrders) {
    if (o.latitude != null && o.longitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId(o.id),
          position: LatLng(o.latitude!, o.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: o.displayCustomerName ?? AppTranslation.customer,
          ),
        ),
      );
    }
  }
  return markers;
}

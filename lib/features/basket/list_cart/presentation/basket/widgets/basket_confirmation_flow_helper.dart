import 'package:flutter/material.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket_order_location_session.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/checkout_location_pick.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/confirmation/pages/basket_confirmation_page.dart';

class BasketConfirmationFlowHelper {
  /// Opens confirmation. Reuses [BasketOrderLocationSession] until the app restarts.
  static Future<void> open(
    BuildContext context,
    ListCartLoaded state,
  ) async {
    if (!BasketOrderLocationSession.hasCoordinates) {
      final picked = await pickCheckoutLocation(context);
      if (picked == null) return;
      BasketOrderLocationSession.save(picked.lat, picked.lng);
    }

    if (!context.mounted) return;

    final lat = BasketOrderLocationSession.latitude!;
    final lng = BasketOrderLocationSession.longitude!;

    final confirmationItems = state.currentItems
        .map(
          (item) => ConfirmationItem(
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        )
        .toList(growable: false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BasketConfirmationPage(
          items: confirmationItems,
          merchantName: state.merchantName,
          latitude: lat,
          longitude: lng,
          initialPhone: state.customerPhone,
        ),
      ),
    );
  }
}

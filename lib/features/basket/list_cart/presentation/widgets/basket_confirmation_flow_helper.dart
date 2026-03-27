import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/features/basket/list_cart/data/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket_order_location_session.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/checkout_location_pick.dart';
import 'package:jeeb_app/features/auth/profile/data/repositories/profile_repository.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/bloc/basket_confirmation_bloc.dart';
import 'package:jeeb_app/features/basket/confirmation_section/presentation/pages/basket_confirmation_page.dart';
import 'package:jeeb_app/features/order/create_order/data/repositories/create_order_repository.dart';

class BasketConfirmationFlowHelper {
  /// Opens confirmation. Reuses [BasketOrderLocationSession] until the app restarts.
  static Future<void> open(BuildContext context, ListCartLoaded state) async {
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
            productId: item.productId,
            isOffer: item.isOffer,
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        )
        .toList(growable: false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => BasketConfirmationBloc(
            items: confirmationItems,
            merchantName: state.merchantName,
            merchantOwnerId: state.merchantOwnerId,
            latitude: lat,
            longitude: lng,
            initialPhone: state.customerPhone,
            orderRepository: di.sl<CreateOrderRepository>(),
            profileRepository: di.sl<ProfileRepository>(),
          ),
          child: const BasketConfirmationPage(),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket/widgets/basket_confirmation_flow_helper.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';

/// Delegates to [BasketConfirmationFlowHelper] (session + single pick per app run).
class BasketConfirmationLauncher {
  static Future<void> open(BuildContext context, ListCartLoaded state) =>
      BasketConfirmationFlowHelper.open(context, state);
}

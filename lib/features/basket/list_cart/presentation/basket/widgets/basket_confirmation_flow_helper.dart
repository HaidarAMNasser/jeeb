import 'package:flutter/material.dart';
import 'package:jeeb_app/core/common/utils/location_permission_helper.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/auth/profile/presentation/widgets/location_map_picker_page.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket/widgets/location_choice_dialog.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/confirmation/pages/basket_confirmation_page.dart';

class BasketConfirmationFlowHelper {
  static Future<void> open(
    BuildContext context,
    ListCartLoaded state,
  ) async {
    final action = await showDialog<LocationChoice>(
      context: context,
      builder: (_) => const LocationChoiceDialog(),
    );
    if (action == null) return;

    double? lat;
    double? lng;

    if (action == LocationChoice.current) {
      final res = await LocationPermissionHelper.requestAndGetPosition();
      lat = res.latitude;
      lng = res.longitude;
      if (lat == null || lng == null) {
        customToast(msg: AppTranslation.locationUnavailable);
        return;
      }
    } else {
      final picked = await Navigator.of(context).push<LocationMapPickerResult>(
        MaterialPageRoute(builder: (_) => const LocationMapPickerPage()),
      );
      if (picked == null) return;
      lat = picked.latitude;
      lng = picked.longitude;
    }

    if (!context.mounted) return;
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
          latitude: lat!,
          longitude: lng!,
          initialPhone: state.customerPhone,
        ),
      ),
    );
  }
}

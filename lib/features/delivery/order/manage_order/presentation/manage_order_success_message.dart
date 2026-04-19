import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';

extension ManageOrderSuccessKindMessage on ManageOrderSuccessKind {
  String get localized {
    switch (this) {
      case ManageOrderSuccessKind.acceptDelivery:
        return AppTranslation.manageOrderSuccessAcceptDelivery;
      case ManageOrderSuccessKind.confirmPickup:
        return AppTranslation.manageOrderSuccessConfirmPickup;
      case ManageOrderSuccessKind.markOnTheWay:
        return AppTranslation.manageOrderSuccessMarkOnTheWay;
      case ManageOrderSuccessKind.markDelivered:
        return AppTranslation.manageOrderSuccessMarkDelivered;
      case ManageOrderSuccessKind.markOrdersPaid:
        return AppTranslation.manageOrderSuccessMarkPaid;
      case ManageOrderSuccessKind.rejectDelivery:
        return AppTranslation.manageOrderSuccessRejectDelivery;
    }
  }
}

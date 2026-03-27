import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

/// Localized copy for the 7 tracking steps (order matches timeline indices 0–6).
class OrderStatusStepLabels {
  OrderStatusStepLabels._();

  static List<String> asList() => [
        AppTranslation.orderStepPlaced,
        AppTranslation.orderStepConfirmed,
        AppTranslation.orderStepSearching,
        AppTranslation.orderStepReady,
        AppTranslation.orderStepWithDriver,
        AppTranslation.orderStepOnTheWay,
        AppTranslation.orderStepDelivered,
      ];
}

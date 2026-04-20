import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

/// Localized titles for the 9 tracking steps (indices 0–8, see [orderStatusToTimelineIndex]).
class OrderStatusStepLabels {
  OrderStatusStepLabels._();

  static List<String> asList() => [
        AppTranslation.orderStepPlaced,
        AppTranslation.orderStepConfirmed,
        AppTranslation.orderStepSearching,
        AppTranslation.orderStepAssigned,
        AppTranslation.orderStepPreparing,
        AppTranslation.orderStepReady,
        AppTranslation.orderStepPickedUpTimeline,
        AppTranslation.orderStepOnTheWay,
        AppTranslation.orderStepDelivered,
      ];
}

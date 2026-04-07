import 'package:easy_localization/easy_localization.dart';

/// **Admin bundle:** only strings needed for order tracking + live map UI.
/// Merge `assets/lang/order_tracking_en.json` (and `ar` if needed) into your app locales,
/// or add the same keys to your existing JSON files.
class AppTranslation {
  AppTranslation._();

  static String get orderStatusProblemBanner =>
      'order_status_problem_banner'.tr();
  static String get orderStatusPendingFriendly =>
      'order_status_pending_friendly'.tr();

  static String get orderStatusLabelConfirmed =>
      'order_status_label_confirmed'.tr();
  static String get orderStatusLabelSearching =>
      'order_status_label_searching'.tr();
  static String get orderStatusLabelPreparing =>
      'order_status_label_preparing'.tr();
  static String get orderStatusLabelReadyForPickup =>
      'order_status_label_ready_for_pickup'.tr();
  static String get orderStatusLabelAssigned =>
      'order_status_label_assigned'.tr();
  static String get orderStatusLabelPickedUp =>
      'order_status_label_picked_up'.tr();
  static String get orderStatusLabelOnTheWay =>
      'order_status_label_on_the_way'.tr();
  static String get orderStatusLabelDelivered =>
      'order_status_label_delivered'.tr();
  static String get orderStatusLabelCancelled =>
      'order_status_label_cancelled'.tr();
  static String get orderStatusLabelRejected =>
      'order_status_label_rejected'.tr();
  static String get orderStatusLabelUnknown =>
      'order_status_label_unknown'.tr();

  static String get orderStepPlaced => 'order_step_placed'.tr();
  static String get orderStepConfirmed => 'order_step_confirmed'.tr();
  static String get orderStepSearching => 'order_step_searching'.tr();
  static String get orderStepPreparing => 'order_step_preparing'.tr();
  static String get orderStepReady => 'order_step_ready'.tr();
  static String get orderStepOnTheWay => 'order_step_on_the_way'.tr();
  static String get orderStepDelivered => 'order_step_delivered'.tr();
  static String get orderStepAssigned => 'order_step_assigned'.tr();
  static String get orderStepPickedUpTimeline =>
      'order_step_picked_up_timeline'.tr();

  static String get orderTrackHintPending => 'order_track_hint_pending'.tr();
  static String get orderTrackHintConfirmed =>
      'order_track_hint_confirmed'.tr();
  static String get orderTrackHintSearching =>
      'order_track_hint_searching'.tr();
  static String get orderTrackHintAssigned =>
      'order_track_hint_assigned'.tr();
  static String orderTrackHintAssignedCourier(String name, String phone) =>
      'order_track_hint_assigned_courier'.tr(
        namedArgs: {'name': name, 'phone': phone.isEmpty ? '—' : phone},
      );
  static String get orderTrackHintPreparing =>
      'order_track_hint_preparing'.tr();
  static String get orderTrackHintReadyForPickup =>
      'order_track_hint_ready_for_pickup'.tr();
  static String get orderTrackHintPickedUp => 'order_track_hint_picked_up'.tr();
  static String get orderTrackHintOnTheWay =>
      'order_track_hint_on_the_way'.tr();
  static String get orderTrackHintDelivered =>
      'order_track_hint_delivered'.tr();
  static String get orderTrackHintCancelled =>
      'order_track_hint_cancelled'.tr();
  static String get orderTrackHintRejected =>
      'order_track_hint_rejected'.tr();
  static String get orderTrackHintUnknown => 'order_track_hint_unknown'.tr();

  static String get orderStatusViewDetails => 'order_status_view_details'.tr();
  static String get orderDeliveryMapBadge => 'order_delivery_map_badge'.tr();
}

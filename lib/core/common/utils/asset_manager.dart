/// Asset Manager - Centralized asset path management
/// Provides easy access to all images and icons used in the app
class AssetManager {
  AssetManager._();
}

/// Image Asset Paths
/// All image assets used in the application
class ImageAsset {
  ImageAsset._();

  // Logo Images
  static const String appLogo = 'assets/images/app_logo.png';
  static const String defaultMarchent = 'assets/images/default_marchent.avif';
  static const String offerDefault = 'assets/images/offer_default.webp';

  /// Order tracking illustrations; folder: `assets/images/order_status/`.
  static const String _orderStatus = 'assets/images/order_status';
  static const String orderStatusPending = '$_orderStatus/pending.png';
  static const String orderStatusConfirmed = '$_orderStatus/confirmed.png';
  static const String orderStatusPreparing = '$_orderStatus/preparing.png';
  static const String orderStatusReadyForPickup =
      '$_orderStatus/ready_for_pickup.png';
  static const String orderStatusAssigned = '$_orderStatus/assigned.png';
  /// Same artwork as [orderStatusAssigned] (shared timeline step).
  static const String orderStatusPickedUp = orderStatusAssigned;
  static const String orderStatusOnTheWay = '$_orderStatus/on_the_way.png';
  static const String orderStatusDelivered = '$_orderStatus/delivered.png';
  /// Same artwork as [orderStatusDelivered].
  static const String orderStatusCompleted = orderStatusDelivered;

  /// Illustration for the journey inner plate; [stepIndex] 0–8 matches
  /// [orderStatusToTimelineIndex] (pending → delivered). Reuses assets where needed.
  static String timelineStepImagePath(int stepIndex) {
    switch (stepIndex.clamp(0, 8)) {
      case 0:
        return orderStatusPending;
      case 1:
        return orderStatusConfirmed;
      case 2:
        return orderStatusPreparing;
      case 3:
        return orderStatusAssigned;
      case 4:
        return orderStatusPreparing;
      case 5:
        return orderStatusReadyForPickup;
      case 6:
        return orderStatusAssigned;
      case 7:
        return orderStatusOnTheWay;
      case 8:
        return orderStatusDelivered;
      default:
        return orderStatusPending;
    }
  }

  // Add more image paths here as needed
  // Example:
  // static const String placeholder = 'assets/images/placeholder.png';
  // static const String background = 'assets/images/background.png';
}

/// Icon Asset Paths
/// All icon assets used in the application
class IconAsset {
  IconAsset._();

  // Add icon paths here as needed
  // Example:
  // static const String customIcon = 'assets/icons/custom_icon.png';
}

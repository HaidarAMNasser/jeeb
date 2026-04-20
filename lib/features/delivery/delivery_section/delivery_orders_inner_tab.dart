import 'package:flutter/foundation.dart';

/// Sub-tabs inside delivery "My orders" (pending / completed / cancelled).
abstract final class DeliveryOrdersInnerTab {
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static void goToCompleted() {
    tabIndex.value = 1;
  }
}

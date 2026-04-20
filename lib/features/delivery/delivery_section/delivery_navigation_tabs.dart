import 'package:flutter/foundation.dart';

/// Programmatic tab switching for the delivery bottom navigation (e.g. jump to orders).
abstract final class DeliveryNavigationTabs {
  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  static void goToOrdersTab() {
    selectedIndex.value = 1;
  }
}

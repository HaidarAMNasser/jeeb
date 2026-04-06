import 'dart:async';

import 'package:flutter/foundation.dart';

/// After **mark delivered**, the home query no longer returns the order, so tracking
/// would immediately start [DriverIdlePresenceReporter] again. Many drivers expect
/// no `/drivers` pings right after completing a drop. This gate suppresses idle
/// presence until [clearAfterManualRefresh] (pull-to-refresh) or [auto-clear] timer.
class DriverIdlePresenceGate extends ChangeNotifier {
  DriverIdlePresenceGate();

  bool _suppress = false;
  Timer? _timer;

  static const Duration autoClearDuration = Duration(minutes: 15);

  bool get suppressIdleAfterDelivery => _suppress;

  void armAfterMarkDelivered() {
    _timer?.cancel();
    _suppress = true;
    notifyListeners();
    _timer = Timer(autoClearDuration, () {
      _suppress = false;
      notifyListeners();
    });
  }

  /// Resume idle `/drivers` presence (e.g. after pull-to-refresh on home).
  void clearAfterManualRefresh() {
    _timer?.cancel();
    _timer = null;
    if (!_suppress) return;
    _suppress = false;
    notifyListeners();
  }
}

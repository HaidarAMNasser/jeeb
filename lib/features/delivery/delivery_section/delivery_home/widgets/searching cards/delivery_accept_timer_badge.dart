import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/order_remaining_time_duration.dart';

/// Round countdown badge showing time left to accept order.
///
/// - On mount: reads `remainingTime.text.seconds` → starts local countdown.
/// - On API refresh (didUpdateWidget with new values & timer not 0):
///   takes the new seconds value and restarts.
/// - When countdown hits 0: fires [onExpired] once (home refresh).
class DeliveryAcceptTimerBadge extends StatefulWidget {
  final OrderEntity order;
  final VoidCallback? onExpired;

  const DeliveryAcceptTimerBadge({
    super.key,
    required this.order,
    this.onExpired,
  });

  @override
  State<DeliveryAcceptTimerBadge> createState() =>
      _DeliveryAcceptTimerBadgeState();
}

class _DeliveryAcceptTimerBadgeState extends State<DeliveryAcceptTimerBadge> {
  Timer? _timer;
  int _initialSeconds = 0;
  int _remainingSeconds = 0;
  bool _didNotifyExpired = false;

  @override
  void initState() {
    super.initState();
    _setFromOrder(widget.order);
    _startTimer();
    _checkExpired();
  }

  @override
  void didUpdateWidget(covariant DeliveryAcceptTimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newSec = OrderRemainingTimeDuration.fromOrder(widget.order).inSeconds;

    // New seconds arrived from API and our timer hasn't hit 0 yet → restart.
    if (newSec > 0 && newSec != _initialSeconds) {
      _timer?.cancel();
      _timer = null;
      _initialSeconds = newSec;
      _remainingSeconds = newSec;
      _didNotifyExpired = false;
      _startTimer();
      setState(() {});
      return;
    }

    // API says 0 → expire.
    if (newSec <= 0 && _remainingSeconds <= 0) {
      _checkExpired();
    }

    // Safety: if timer died, restart.
    if (_timer == null && _remainingSeconds > 0) {
      _startTimer();
    }
  }

  void _setFromOrder(OrderEntity order) {
    final d = OrderRemainingTimeDuration.fromOrder(order);
    _initialSeconds = d.inSeconds;
    _remainingSeconds = _initialSeconds;
    _didNotifyExpired = false;
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _remainingSeconds - 1;
      if (next <= 0) {
        _timer?.cancel();
        _timer = null;
        setState(() => _remainingSeconds = 0);
        _checkExpired();
        return;
      }
      setState(() => _remainingSeconds = next);
    });
  }

  void _checkExpired() {
    if (_didNotifyExpired || _remainingSeconds > 0) return;
    _didNotifyExpired = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onExpired?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int totalSec) {
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final secs = _remainingSeconds.clamp(0, 1 << 30);
    final progress =
        (_initialSeconds > 0) ? (secs / _initialSeconds).clamp(0.0, 1.0) : 0.0;

    final danger = secs <= 10;
    final accent = danger ? const Color(0xFFFF4D6D) : ColorManager.primary;

    return Container(
      width: AppSize.s70,
      height: AppSize.s70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: accent.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: AppSize.s70,
            height: AppSize.s70,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: AppSize.s20, color: accent),
              const SizedBox(height: 2),
              SizedBox(
                width: AppSize.s60,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CustomText(
                    text: secs > 0 ? _fmt(secs) : '—',
                    textStyle: getBoldStyle(
                      fontSize: AppFontSize.s11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

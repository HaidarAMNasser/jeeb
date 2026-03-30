import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Countdown until [OrderEntity.deliveryDeadline] or `remainingTime` (same as home available card).
class DeliveryOrderDeadlineCountdown extends StatefulWidget {
  final OrderEntity order;
  final VoidCallback? onExpired;

  const DeliveryOrderDeadlineCountdown({
    super.key,
    required this.order,
    this.onExpired,
  });

  @override
  State<DeliveryOrderDeadlineCountdown> createState() =>
      _DeliveryOrderDeadlineCountdownState();
}

class _DeliveryOrderDeadlineCountdownState
    extends State<DeliveryOrderDeadlineCountdown> {
  Timer? _timer;
  int _secondsLeft = -1;
  bool _firedExpired = false;

  static const int _maxReasonableMinutes = 10080; // 7 days

  @override
  void initState() {
    super.initState();
    _secondsLeft = _computeInitialSeconds();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant DeliveryOrderDeadlineCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _computeInitialSeconds();
    if (next != _secondsLeft) {
      _timer?.cancel();
      setState(() {
        _secondsLeft = next;
        _firedExpired = false;
      });
      _startTicker();
    }
  }

  int _computeInitialSeconds() {
    final o = widget.order;
    if (o.deliveryDeadline != null) {
      final s = o.deliveryDeadline!.difference(DateTime.now()).inSeconds;
      return s > 0 ? s : 0;
    }
    final rt = o.remainingTime?.text;
    if (rt == null) return -1;
    final m = rt.minutes ?? 0;
    final sec = rt.seconds ?? 0;
    if (m > _maxReasonableMinutes) return -1;
    return m * 60 + sec;
  }

  void _startTicker() {
    if (_secondsLeft <= 0) {
      if (_secondsLeft == 0 && !_firedExpired) {
        _firedExpired = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onExpired?.call();
        });
      }
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _timer = null;
        if (!_firedExpired) {
          _firedExpired = true;
          widget.onExpired?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatHms(int seconds) {
    if (seconds < 0) return '';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.order.remainingTime?.displayLabel;

    return Container(
      constraints: BoxConstraints(maxWidth: AppWidth.s100),
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSize.s12),
      ),
      child: _secondsLeft > 0
          ? CustomText(
              text: _formatHms(_secondsLeft),
              textAlign: TextAlign.end,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s14,
                color: Colors.redAccent,
              ),
            )
          : (label != null && label.isNotEmpty
              ? CustomText(
                  text: label,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s10,
                    color: Colors.redAccent,
                  ),
                )
              : CustomText(
                  text: '—',
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s14,
                    color: Colors.redAccent,
                  ),
                )),
    );
  }
}

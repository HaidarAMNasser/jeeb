import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Counts down to [placedAt] + [preparationMinutes]. Fires [onElapsed] once at zero.
class DeliveryOrderMealPrepCountdown extends StatefulWidget {
  final DateTime? placedAt;
  final int? preparationMinutes;
  final VoidCallback? onElapsed;

  const DeliveryOrderMealPrepCountdown({
    super.key,
    this.placedAt,
    this.preparationMinutes,
    this.onElapsed,
  });

  @override
  State<DeliveryOrderMealPrepCountdown> createState() =>
      _DeliveryOrderMealPrepCountdownState();
}

class _DeliveryOrderMealPrepCountdownState
    extends State<DeliveryOrderMealPrepCountdown> {
  Timer? _timer;
  int _secondsLeft = 0;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _initialSeconds();
    _start();
  }

  @override
  void didUpdateWidget(covariant DeliveryOrderMealPrepCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placedAt != widget.placedAt ||
        oldWidget.preparationMinutes != widget.preparationMinutes) {
      _timer?.cancel();
      _fired = false;
      _secondsLeft = _initialSeconds();
      _start();
    }
  }

  int _initialSeconds() {
    final mins = widget.preparationMinutes;
    if (mins == null || mins <= 0) return 0;
    final start = widget.placedAt ?? DateTime.now();
    final end = start.add(Duration(minutes: mins));
    final s = end.difference(DateTime.now()).inSeconds;
    return s > 0 ? s : 0;
  }

  void _start() {
    if (_secondsLeft <= 0) {
      if (_secondsLeft == 0 && !_fired) {
        _fired = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => widget.onElapsed?.call());
      }
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _timer = null;
        if (!_fired) {
          _fired = true;
          widget.onElapsed?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mins = widget.preparationMinutes;
    if (mins == null || mins <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          text: AppTranslation.orderMealPrepRemaining,
          textStyle: getRegularStyle(
            fontSize: AppFontSize.s10,
            color: ColorManager.textSecondary,
          ),
        ),
        SizedBox(height: AppHeight.s4),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p10,
            vertical: AppPadding.p6,
          ),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSize.s10),
          ),
          child: CustomText(
            text: _secondsLeft > 0 ? _fmt(_secondsLeft) : '00:00',
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.primary,
            ),
          ),
        ),
      ],
    );
  }
}

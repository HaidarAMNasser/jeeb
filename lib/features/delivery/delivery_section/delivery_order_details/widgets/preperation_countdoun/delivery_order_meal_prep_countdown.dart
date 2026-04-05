import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/preperation_countdoun/delivery_order_hms_slide_countdown.dart';

/// Counts down to [placedAt] + [preparationMinutes] using [SlideCountdownSeparated] (H:MM:SS).
/// Stable [orderId] key keeps the slide timer from restarting on parent rebuilds.
class DeliveryOrderMealPrepCountdown extends StatefulWidget {
  final String orderId;
  final DateTime? placedAt;
  final int? preparationMinutes;
  final VoidCallback? onElapsed;

  /// Horizontal layout: label and timer on one row.
  final bool compact;

  const DeliveryOrderMealPrepCountdown({
    super.key,
    required this.orderId,
    this.placedAt,
    this.preparationMinutes,
    this.onElapsed,
    this.compact = false,
  });

  @override
  State<DeliveryOrderMealPrepCountdown> createState() =>
      _DeliveryOrderMealPrepCountdownState();
}

class _DeliveryOrderMealPrepCountdownState
    extends State<DeliveryOrderMealPrepCountdown> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeDuration();
  }

  @override
  void didUpdateWidget(covariant DeliveryOrderMealPrepCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placedAt != widget.placedAt ||
        oldWidget.preparationMinutes != widget.preparationMinutes) {
      setState(() => _remaining = _computeDuration());
    }
  }

  Duration _computeDuration() {
    final mins = widget.preparationMinutes;
    if (mins == null || mins <= 0) return Duration.zero;
    final start = widget.placedAt ?? DateTime.now();
    final end = start.add(Duration(minutes: mins));
    final s = end.difference(DateTime.now()).inSeconds;
    return Duration(seconds: s > 0 ? s : 0);
  }

  @override
  Widget build(BuildContext context) {
    final mins = widget.preparationMinutes;
    if (mins == null || mins <= 0) return const SizedBox.shrink();

    final doneLabel = CustomText(
      text: '00:00:00',
      textStyle: getSemiBoldStyle(
        fontSize: AppFontSize.s14,
        color: ColorManager.primary,
      ),
    );

    final timer = DeliveryOrderHmsSlideCountdown(
      key: ValueKey('meal_slide_${widget.orderId}'),
      remaining: _remaining,
      variant: DeliveryOrderCountdownVariant.mealPrep,
      dense: widget.compact,
      onDone: widget.onElapsed,
      replacementIfAlreadyElapsed: doneLabel,
      replacementWhenDone: doneLabel,
    );

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            text: AppTranslation.orderMealPrepRemaining,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s10,
              color: ColorManager.textSecondary,
            ),
          ),
          SizedBox(width: AppWidth.s8),
          Flexible(child: timer),
        ],
      );
    }

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
        timer,
      ],
    );
  }
}

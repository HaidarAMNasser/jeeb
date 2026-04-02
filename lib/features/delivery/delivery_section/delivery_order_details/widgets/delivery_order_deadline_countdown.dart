import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/preperation_countdoun/delivery_order_hms_slide_countdown.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/order_remaining_time_duration.dart';

/// Countdown from [OrderEntity.remainingTime] only (see [OrderRemainingTimeDuration]).
/// Uses [SlideCountdown] with **H:MM:SS** display.
class DeliveryOrderDeadlineCountdown extends StatefulWidget {
  final OrderEntity order;
  final VoidCallback? onExpired;
  final bool dense;
  final double maxWidth;
  final double? fontSize;
  final double? iconSize;

  const DeliveryOrderDeadlineCountdown({
    super.key,
    required this.order,
    this.onExpired,
    this.dense = false,
    this.maxWidth = 100,
    this.fontSize,
    this.iconSize,
  });

  @override
  State<DeliveryOrderDeadlineCountdown> createState() =>
      _DeliveryOrderDeadlineCountdownState();
}

class _DeliveryOrderDeadlineCountdownState
    extends State<DeliveryOrderDeadlineCountdown> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeDuration();
  }

  @override
  void didUpdateWidget(covariant DeliveryOrderDeadlineCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_orderTimingChanged(oldWidget.order, widget.order)) {
      setState(() => _remaining = _computeDuration());
    }
  }

  bool _orderTimingChanged(OrderEntity a, OrderEntity b) {
    return a.remainingTime != b.remainingTime;
  }

  Duration _computeDuration() {
    return OrderRemainingTimeDuration.fromOrder(widget.order);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.order.remainingTime?.displayLabel;

    final doneOrEmpty = label != null && label.isNotEmpty
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
          );

    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: DeliveryOrderHmsSlideCountdown(
          // Keep a stable key so the internal slide countdown doesn't restart
          // on list rebuilds / periodic refreshes.
          key: ValueKey('deadline_${widget.order.id}'),
          remaining: _remaining,
          variant: DeliveryOrderCountdownVariant.deadline,
          dense: widget.dense,
          fontSize: widget.fontSize,
          iconSizeOverride: widget.iconSize,
          onDone: widget.onExpired,
          replacementIfAlreadyElapsed: doneOrEmpty,
          replacementWhenDone: doneOrEmpty,
        ),
      ),
    );
  }
}

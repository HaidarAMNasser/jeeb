import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

/// Shared status pill for delivery cards and order details (distinct color per [OrderStatus]).
class DeliveryOrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool compact;

  /// When set (e.g. delivery mediator payment copy), overrides [OrderStatus.displayLabel].
  final String? labelOverride;

  const DeliveryOrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.labelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    final padH = compact ? AppPadding.p8 : AppPadding.p12;
    final padV = compact ? AppPadding.p4 : AppPadding.p6;
    final fontSize = compact ? AppFontSize.s10 : AppFontSize.s12;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSize.s10),
        border: Border.all(color: c.withValues(alpha: 0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.12),
            blurRadius: compact ? 4 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconSize = compact ? 14.0 : 16.0;
          final gap = AppWidth.s4;
          final label = CustomText(
            text: labelOverride ?? status.displayLabel,
            textStyle: getBoldStyle(fontSize: fontSize, color: c),
            maxLines: 1,
            softWrap: false,
            textOverflow: TextOverflow.ellipsis,
          );

          if (!constraints.maxWidth.isFinite) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.iconData, size: iconSize, color: c),
                SizedBox(width: gap),
                label,
              ],
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(status.iconData, size: iconSize, color: c),
              SizedBox(width: gap),
              Expanded(child: label),
            ],
          );
        },
      ),
    );
  }
}

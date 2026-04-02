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

  const DeliveryOrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
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
        color: c.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppSize.s10),
        border: Border.all(color: c.withOpacity(0.45), width: 1),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.12),
            blurRadius: compact ? 4 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.iconData, size: compact ? 14 : 16, color: c),
          SizedBox(width: AppWidth.s4),
          CustomText(
            text: status.displayLabel,
            textStyle: getBoldStyle(fontSize: fontSize, color: c),
          ),
        ],
      ),
    );
  }
}

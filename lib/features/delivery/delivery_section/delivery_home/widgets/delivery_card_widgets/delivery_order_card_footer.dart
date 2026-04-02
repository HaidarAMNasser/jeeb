import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class DeliveryOrderCardFooter extends StatelessWidget {
  final String orderId;
  final String? status;
  final bool enableRealtimeStatus;

  const DeliveryOrderCardFooter({
    super.key,
    required this.orderId,
    this.status,
    this.enableRealtimeStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseText = status ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!enableRealtimeStatus)
          CustomText(
            text: baseText,
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s10,
              color: ColorManager.primary.withOpacity(0.7),
            ),
          )
        else
          StreamBuilder<String?>(
            stream: di.sl<OrderStatusRtdbService>().watchOrderStatusWire(orderId),
            builder: (context, snap) {
              final wire = snap.data?.trim();
              final display = (wire != null && wire.isNotEmpty)
                  ? OrderStatus.fromString(wire).displayLabel
                  : baseText;
              return CustomText(
                text: display,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s10,
                  color: ColorManager.primary.withOpacity(0.7),
                ),
              );
            },
          ),
        CustomText(
          text: 'Order #$orderId',
          textStyle: TextStyle(
            fontSize: AppFontSize.s10,
            color: ColorManager.textSecondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/shared/widgets/delivery_order_status_badge.dart';

/// Status + whisper-quiet order reference (non-searching cards).
class DeliveryOrderCardTopBar extends StatelessWidget {
  final String orderId;
  final String? initialStatusWire;
  final bool enableRealtimeStatus;

  const DeliveryOrderCardTopBar({
    super.key,
    required this.orderId,
    this.initialStatusWire,
    this.enableRealtimeStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          flex: 2,
          child: enableRealtimeStatus
              ? StreamBuilder<String?>(
                  stream: di
                      .sl<OrderStatusRtdbService>()
                      .watchOrderStatusWire(orderId),
                  builder: (context, snap) {
                    final wire = snap.data?.trim();
                    final effective = (wire != null && wire.isNotEmpty)
                        ? wire
                        : (initialStatusWire ?? '');
                    final status = OrderStatus.fromString(effective);
                    return DeliveryOrderStatusBadge(
                      status: status,
                      compact: true,
                    );
                  },
                )
              : DeliveryOrderStatusBadge(
                  status: OrderStatus.fromString(initialStatusWire),
                  compact: true,
                ),
        ),
        SizedBox(width: AppWidth.s10),
        Flexible(
          flex: 1,
          child: Text(
            '#$orderId',
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: getMediumStyle(
              fontSize: AppFontSize.s11,
              color: ColorManager.textSecondary.withOpacity(0.65),
            ).copyWith(letterSpacing: 0.3),
          ),
        ),
      ],
    );
  }
}

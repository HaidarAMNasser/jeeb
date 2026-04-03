import 'package:flutter/material.dart';
import 'package:jeeb_app/features/delivery/shared/widgets/delivery_order_status_badge.dart';

import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class OrderDetailsStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderDetailsStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return DeliveryOrderStatusBadge(status: status);
  }
}

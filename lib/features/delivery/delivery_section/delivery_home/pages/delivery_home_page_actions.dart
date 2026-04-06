import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/driver_idle_presence_gate.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/widgets/accept_delivery_estimated_time_dialog.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

bool deliveryHomeCanPullToRefresh(DeliveryHomeState state) {
  return state is DeliveryHomeLoaded || state is DeliveryHomeError;
}

Future<void> deliveryHomePullToRefresh(BuildContext context) async {
  final bloc = context.read<DeliveryHomeBloc>();
  final next = bloc.stream.firstWhere(
    (s) => s is DeliveryHomeLoaded || s is DeliveryHomeError,
  );
  bloc.add(const RefreshDeliveryHomeEvent());
  try {
    await next.timeout(const Duration(seconds: 45));
  } on TimeoutException {
    // Allow RefreshIndicator to hide if no new state is emitted.
  }
  di.sl<DriverIdlePresenceGate>().clearAfterManualRefresh();
}

/// Cooldown + loading guard for RTDB-driven home refresh.
class DeliveryHomeAutoRefreshGate {
  DateTime? _last;
  static const Duration _cooldown = Duration(seconds: 8);

  void safeRefresh(BuildContext context) {
    if (!context.mounted) return;
    final now = DateTime.now();
    if (_last != null && now.difference(_last!) < _cooldown) return;
    if (context.read<DeliveryHomeBloc>().state is DeliveryHomeLoading) return;
    _last = now;
    context.read<DeliveryHomeBloc>().add(const RefreshDeliveryHomeEvent());
  }
}

Future<void> deliveryHomeConfirmAcceptOrder(
  BuildContext context,
  OrderEntity order,
) async {
  final minutes = await AcceptDeliveryEstimatedTimeDialog.show(context);
  if (!context.mounted || minutes == null) return;
  context.read<ManageOrderBloc>().add(
    AcceptDeliveryEvent(id: order.id, deliveryTime: minutes),
  );
}

void deliveryHomeOpenOrderDetails(BuildContext context, OrderEntity order) {
  Navigator.pushNamed(
    context,
    Routes.deliveryOrderDetails,
    arguments: {'orderId': order.id},
  );
}

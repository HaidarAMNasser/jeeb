import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/tracking/domain/repositories/delivery_tracking_repository.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_order_location_reporter.dart';

/// Hosts [DeliveryOrderLocationReporter] above the delivery tab body so GPS → API + RTDB
/// `/drivers/{id}` keeps running when switching Home / My orders / Profile.
class DeliveryPersistentTrackingScope extends StatefulWidget {
  const DeliveryPersistentTrackingScope({super.key, required this.child});

  final Widget child;

  @override
  State<DeliveryPersistentTrackingScope> createState() =>
      _DeliveryPersistentTrackingScopeState();
}

class _DeliveryPersistentTrackingScopeState
    extends State<DeliveryPersistentTrackingScope> {
  DeliveryOrderLocationReporter? _reporter;

  @override
  void dispose() {
    _reporter?.dispose();
    super.dispose();
  }

  int? _profileUserId(ProfileState state) {
    if (state is ProfileLoaded) return state.user.id;
    return null;
  }

  String? _assignedOrderIdFromState(DeliveryHomeState state) {
    if (state is DeliveryHomeLoaded && state.assignedOrder != null) {
      return state.assignedOrder!.id;
    }
    return null;
  }

  String? _assignedOrderStatusFromState(DeliveryHomeState state) {
    if (state is DeliveryHomeLoaded && state.assignedOrder != null) {
      return state.assignedOrder!.status;
    }
    return null;
  }

  void _syncReporter(DeliveryHomeState homeState) {
    if (!mounted) return;
    final driverId = _profileUserId(context.read<ProfileBloc>().state);
    if (driverId == null || driverId <= 0) {
      _reporter?.dispose();
      _reporter = null;
      return;
    }

    if (homeState is! DeliveryHomeLoaded || homeState.assignedOrder == null) {
      _reporter?.dispose();
      _reporter = null;
      return;
    }

    final order = homeState.assignedOrder!;
    final orderId = int.tryParse(order.id);
    final status = OrderStatus.fromString(order.status);
    if (orderId == null || !DeliveryOrderLocationReporter.shouldTrack(status)) {
      _reporter?.dispose();
      _reporter = null;
      return;
    }

    if (_reporter != null && _reporter!.orderId == orderId) {
      _reporter!.ensureStarted();
      return;
    }

    _reporter?.dispose();
    _reporter = DeliveryOrderLocationReporter(
      orderId: orderId,
      driverId: driverId,
      repository: di.sl<DeliveryTrackingRepository>(),
      rtdb: di.sl<OrderStatusRtdbService>(),
    );
    _reporter!.ensureStarted();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncReporter(context.read<DeliveryHomeBloc>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          // GetProfile() emits ProfileLoading with no user id — ignore so we don't
          // tear down the reporter (and avoid fighting home/profile init).
          listenWhen: (prev, cur) {
            if (cur is ProfileLoading) return false;
            return _profileUserId(prev) != _profileUserId(cur);
          },
          listener: (context, state) {
            _syncReporter(context.read<DeliveryHomeBloc>().state);
          },
        ),
        BlocListener<DeliveryHomeBloc, DeliveryHomeState>(
          listenWhen: (prev, cur) =>
              _assignedOrderIdFromState(prev) !=
                  _assignedOrderIdFromState(cur) ||
              _assignedOrderStatusFromState(prev) !=
                  _assignedOrderStatusFromState(cur),
          listener: (context, state) => _syncReporter(state),
        ),
      ],
      child: widget.child,
    );
  }
}

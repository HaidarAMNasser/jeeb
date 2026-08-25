import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/tracking/domain/repositories/delivery_tracking_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_order_location_reporter.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_tracking_position_binding.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/driver_idle_presence_gate.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/driver_idle_presence_reporter.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/fake_delivery_tracking_controller.dart';

/// Hosts live tracking above the delivery tab:
/// - **[DeliveryOrderLocationReporter]**: order route API **only** when there is an assigned
///   order and its status is [OrderStatus.onTheWay].
/// - **[DriverIdlePresenceReporter]**: RTDB `/drivers/{id}` with `isOnline: true` while the
///   app is in the foreground and the driver has **no** assigned order (available / pool).
///   Background / kill → reporter dispose + onDisconnect set `isOnline: false`.
class DeliveryPersistentTrackingScope extends StatefulWidget {
  const DeliveryPersistentTrackingScope({super.key, required this.child});

  final Widget child;

  @override
  State<DeliveryPersistentTrackingScope> createState() =>
      _DeliveryPersistentTrackingScopeState();
}

class _DeliveryPersistentTrackingScopeState
    extends State<DeliveryPersistentTrackingScope>
    with WidgetsBindingObserver {
  DeliveryOrderLocationReporter? _orderReporter;
  DriverIdlePresenceReporter? _idleReporter;
  late final FakeDeliveryTrackingController _fakeTracking;
  late final DriverIdlePresenceGate _idleGate;
  bool _orderReporterUsedFakeStream = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  bool get _isAppInForeground =>
      _lifecycleState == AppLifecycleState.resumed ||
      _lifecycleState == AppLifecycleState.inactive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fakeTracking = di.sl<FakeDeliveryTrackingController>();
    _idleGate = di.sl<DriverIdlePresenceGate>();
    _fakeTracking.addListener(_onFakeTrackingChanged);
    _idleGate.addListener(_onIdleGateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncReporter(context.read<DeliveryHomeBloc>().state);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (!mounted) return;
    _syncReporter(context.read<DeliveryHomeBloc>().state);
  }

  void _onFakeTrackingChanged() {
    if (!mounted) return;
    _syncReporter(context.read<DeliveryHomeBloc>().state);
  }

  void _onIdleGateChanged() {
    if (!mounted) return;
    _syncReporter(context.read<DeliveryHomeBloc>().state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleGate.removeListener(_onIdleGateChanged);
    _fakeTracking.removeListener(_onFakeTrackingChanged);
    _orderReporter?.dispose();
    _idleReporter?.dispose();
    super.dispose();
  }

  int? _profileUserId(ProfileState state) {
    if (state is ProfileLoaded) return state.user.id;
    return null;
  }

  void _syncReporter(DeliveryHomeState homeState) {
    if (!mounted) return;
    final profileState = context.read<ProfileBloc>().state;
    final driverId = _profileUserId(profileState);
    if (kDebugMode) {
      debugPrint(
        '[PersistentTrackingScope] _syncReporter: '
        'profileState=${profileState.runtimeType} driverId=$driverId '
        'foreground=$_isAppInForeground lifecycle=$_lifecycleState',
      );
    }
    if (driverId == null || driverId <= 0) {
      _orderReporter?.dispose();
      _orderReporter = null;
      _idleReporter?.dispose();
      _idleReporter = null;
      _orderReporterUsedFakeStream = false;
      return;
    }

    final fake = di.sl<FakeDeliveryTrackingController>();
    final useFake = fake.simulating;

    final order =
        (homeState is DeliveryHomeLoaded) ? homeState.assignedOrder : null;
    final hasAssignedOrder = order != null;
    final parsed = OrderStatus.fromString(order?.status);
    final isOnTheWay = order != null && parsed == OrderStatus.onTheWay;
    final orderIdInt = order != null ? (int.tryParse(order.id) ?? 0) : 0;
    final useOrderTracking = isOnTheWay && orderIdInt > 0;

    if (useOrderTracking) {
      _idleReporter?.dispose();
      _idleReporter = null;

      if (_orderReporter != null &&
          _orderReporter!.orderId == orderIdInt &&
          _orderReporterUsedFakeStream == useFake) {
        _orderReporter!.ensureStarted();
        return;
      }

      _orderReporter?.dispose();
      _orderReporter = DeliveryOrderLocationReporter(
        orderId: orderIdInt,
        repository: di.sl<DeliveryTrackingRepository>(),
        positionStream: useFake ? fake.movementStreamFor(order) : null,
      );
      _orderReporterUsedFakeStream = useFake;
      _orderReporter!.ensureStarted();
      return;
    }

    _orderReporter?.dispose();
    _orderReporter = null;
    _orderReporterUsedFakeStream = false;

    // Assigned (accepted) job but not yet ON_THE_WAY: do not send /drivers or order API.
    if (hasAssignedOrder) {
      _idleReporter?.dispose();
      _idleReporter = null;
      return;
    }

    // App not in foreground — stop presence (dispose marks isOnline: false).
    if (!_isAppInForeground) {
      _idleReporter?.dispose();
      _idleReporter = null;
      return;
    }

    if (di.sl<DriverIdlePresenceGate>().suppressIdleAfterDelivery) {
      _idleReporter?.dispose();
      _idleReporter = null;
      return;
    }

    if (_idleReporter != null && _idleReporter!.driverId == driverId) {
      _idleReporter!.ensureStarted();
      return;
    }

    _idleReporter?.dispose();
    unawaited(
      di.sl<OrderStatusRtdbService>().armDriverOfflineOnDisconnect(driverId),
    );
    _idleReporter = DriverIdlePresenceReporter(
      driverId: driverId,
      rtdb: di.sl<OrderStatusRtdbService>(),
    );
    _idleReporter!.ensureStarted();
  }

  void _forwardPositionToReporter(Position p) {
    _orderReporter?.reportPosition(p);
    _idleReporter?.reportPosition(p);
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryTrackingPositionBinding(
      forward: _forwardPositionToReporter,
      child: MultiBlocListener(
        listeners: [
          BlocListener<ProfileBloc, ProfileState>(
            listenWhen: (prev, cur) {
              if (cur is ProfileLoading) return false;
              return _profileUserId(prev) != _profileUserId(cur);
            },
            listener: (context, state) {
              _syncReporter(context.read<DeliveryHomeBloc>().state);
            },
          ),
          BlocListener<DeliveryHomeBloc, DeliveryHomeState>(
            // Any home state change (incl. full reload after deliver) must re-evaluate tracking.
            listenWhen: (prev, cur) => prev != cur,
            listener: (context, state) => _syncReporter(state),
          ),
        ],
        child: widget.child,
      ),
    );
  }
}

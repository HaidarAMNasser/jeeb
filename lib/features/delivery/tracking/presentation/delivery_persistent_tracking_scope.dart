import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/tracking/domain/repositories/delivery_tracking_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_order_location_reporter.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_tracking_position_binding.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/fake_delivery_tracking_controller.dart';

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
  late final FakeDeliveryTrackingController _fakeTracking;
  bool _reporterUsedFakeStream = false;

  @override
  void initState() {
    super.initState();
    _fakeTracking = di.sl<FakeDeliveryTrackingController>();
    _fakeTracking.addListener(_onFakeTrackingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncReporter(context.read<DeliveryHomeBloc>().state);
    });
  }

  void _onFakeTrackingChanged() {
    if (!mounted) return;
    _syncReporter(context.read<DeliveryHomeBloc>().state);
  }

  @override
  void dispose() {
    _fakeTracking.removeListener(_onFakeTrackingChanged);
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
    final profileState = context.read<ProfileBloc>().state;
    final driverId = _profileUserId(profileState);
    if (kDebugMode) {
      debugPrint(
        '[PersistentTrackingScope] _syncReporter: '
        'profileState=${profileState.runtimeType} driverId=$driverId',
      );
    }
    if (driverId == null || driverId <= 0) {
      _reporter?.dispose();
      _reporter = null;
      _reporterUsedFakeStream = false;
      return;
    }

    final fake = di.sl<FakeDeliveryTrackingController>();
    final useFake = fake.simulating;

    // Resolve assigned order info (may be null).
    final order = (homeState is DeliveryHomeLoaded)
        ? homeState.assignedOrder
        : null;
    final orderId = order != null ? (int.tryParse(order.id) ?? 0) : 0;

    // Already have a matching reporter → keep it running.
    if (_reporter != null &&
        _reporter!.orderId == orderId &&
        _reporterUsedFakeStream == useFake) {
      _reporter!.ensureStarted();
      return;
    }

    // (Re)create the reporter — always active for driver presence,
    // uses real GPS by default; fake stream only when simulating an order.
    _reporter?.dispose();
    _reporter = DeliveryOrderLocationReporter(
      orderId: orderId,
      driverId: driverId,
      repository: di.sl<DeliveryTrackingRepository>(),
      rtdb: di.sl<OrderStatusRtdbService>(),
      positionStream: useFake && order != null
          ? fake.movementStreamFor(order)
          : null,
    );
    _reporterUsedFakeStream = useFake;
    _reporter!.ensureStarted();
  }

  void _forwardPositionToReporter(Position p) {
    _reporter?.reportPosition(p);
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryTrackingPositionBinding(
      forward: _forwardPositionToReporter,
      child: MultiBlocListener(
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
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_home_app_bar.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/controllers/delivery_location_controller.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/controllers/delivery_order_status_watcher.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/controllers/delivery_route_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_home_map_section.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_home_orders_section.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_route_legende.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/manage_order_success_message.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/widgets/accept_delivery_estimated_time_dialog.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/presentation/maps/delivery_map_marker_bitmaps.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_tracking_position_binding.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/fake_delivery_tracking_controller.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/fake_delivery_tracking_demo_bar.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage>
    with WidgetsBindingObserver {
  late final DeliveryLocationController _locationController;
  late final DeliveryRouteManager _routeManager;
  late final DeliveryOrderStatusWatcher _orderStatusWatcher;

  DateTime? _lastAutoRefreshAt;
  static const Duration _autoRefreshCooldown = Duration(seconds: 8);

  Timer? _routeSyncTimer;
  Timer? _resumeRefreshTimer;
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropoffMarkerIcon;
  BitmapDescriptor? _driverMarkerIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationController = DeliveryLocationController();
    _routeManager = DeliveryRouteManager();
    _orderStatusWatcher = DeliveryOrderStatusWatcher(
      onStatusChanged: _safeAutoRefreshHome,
    );
    _locationController.start();
    _locationController.addListener(_onLocationChangedForRoutes);
    DeliveryMapMarkerBitmaps.pickup().then((b) {
      if (mounted) setState(() => _pickupMarkerIcon = b);
    });
    DeliveryMapMarkerBitmaps.dropoff().then((b) {
      if (mounted) setState(() => _dropoffMarkerIcon = b);
    });
    DeliveryMapMarkerBitmaps.driver().then((b) {
      if (mounted) setState(() => _driverMarkerIcon = b);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProfileThenHome();
    });
  }

  void _onLocationChangedForRoutes() {
    _routeSyncTimer?.cancel();
    _routeSyncTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _routeManager.syncPlannedDrivingRoute(
        context.read<DeliveryHomeBloc>().state,
        driverLat: _locationController.currentLat,
        driverLng: _locationController.currentLng,
      );
    });
  }

  /// Fetches profile first; once loaded (or already cached), fires the home orders load.
  Future<void> _loadProfileThenHome() async {
    if (!mounted) return;
    final profileBloc = context.read<ProfileBloc>();
    final currentState = profileBloc.state;

    final alreadyLoaded =
        currentState is ProfileLoaded &&
        '${currentState.user.firstName} ${currentState.user.lastName}'
            .trim()
            .isNotEmpty;

    if (!alreadyLoaded) {
      profileBloc.add(const GetProfile());
      await profileBloc.stream
          .firstWhere((s) => s is ProfileLoaded || s is ProfileError)
          .timeout(const Duration(seconds: 10), onTimeout: () => currentState);
    }

    if (!mounted) return;

    final profileAfter = context.read<ProfileBloc>().state;
    if (profileAfter is ProfileLoaded) {
      await di.sl<OrderStatusRtdbService>().ensureFirebaseAuthForDriver(
        profileAfter.user.id,
      );
    }

    if (!mounted) return;
    final homeBloc = context.read<DeliveryHomeBloc>();
    homeBloc.add(const LoadDeliveryHomeEvent());
    _routeManager.syncAssignedRouteHistorySubscription(homeBloc.state);
    _routeManager.syncPlannedDrivingRoute(
      homeBloc.state,
      driverLat: _locationController.currentLat,
      driverLng: _locationController.currentLng,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locationController.onPositionUpdate = (Position p) {
      if (!mounted) return;
      DeliveryTrackingPositionBinding.maybeOf(context)?.forward(p);
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefreshAfterResume();
    }
  }

  void _scheduleRefreshAfterResume() {
    _resumeRefreshTimer?.cancel();
    _resumeRefreshTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final bloc = context.read<DeliveryHomeBloc>();
      if (bloc.state is DeliveryHomeLoading) return;
      bloc.add(const RefreshDeliveryHomeEvent());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeRefreshTimer?.cancel();
    _routeSyncTimer?.cancel();
    _locationController.removeListener(_onLocationChangedForRoutes);
    _locationController.dispose();
    _routeManager.dispose();
    _orderStatusWatcher.dispose();
    super.dispose();
  }

  bool _canPullToRefreshDeliveryHome(DeliveryHomeState state) {
    return state is DeliveryHomeLoaded || state is DeliveryHomeError;
  }

  Future<void> _pullToRefreshDeliveryHome() async {
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
  }

  void _safeAutoRefreshHome() {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastAutoRefreshAt;
    if (last != null && now.difference(last) < _autoRefreshCooldown) return;
    if (context.read<DeliveryHomeBloc>().state is DeliveryHomeLoading) return;
    _lastAutoRefreshAt = now;
    context.read<DeliveryHomeBloc>().add(const RefreshDeliveryHomeEvent());
  }

  Future<void> _confirmAcceptOrder(OrderEntity order) async {
    final minutes = await AcceptDeliveryEstimatedTimeDialog.show(context);
    if (!mounted || minutes == null) return;
    context.read<ManageOrderBloc>().add(
      AcceptDeliveryEvent(id: order.id, deliveryTime: minutes),
    );
  }

  void _onOrderTap(OrderEntity order) {
    Navigator.pushNamed(
      context,
      Routes.deliveryOrderDetails,
      arguments: {'orderId': order.id},
    );
  }

  Set<Marker> _buildMarkers(DeliveryHomeState state) {
    if (state is DeliveryHomeLoaded) {
      final Set<Marker> markers = {};

      if (state.assignedOrder != null) {
        final o = state.assignedOrder!;
        final restaurantName =
            o.owner?.restaurantName?.trim().isNotEmpty == true
            ? o.owner!.restaurantName!
            : AppTranslation.restaurantName;
        final rLat = o.restaurantLatitude;
        final rLng = o.restaurantLongitude;
        final dLat = o.dropoffLatitude;
        final dLng = o.dropoffLongitude;

        if (rLat != null && rLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('pickup_${o.id}'),
              position: LatLng(rLat, rLng),
              icon:
                  _pickupMarkerIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
              infoWindow: InfoWindow(
                title: restaurantName,
                snippet: o.owner?.address ?? o.pickupAddress,
              ),
            ),
          );
        }
        if (dLat != null && dLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('dropoff_${o.id}'),
              position: LatLng(dLat, dLng),
              icon:
                  _dropoffMarkerIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
              infoWindow: InfoWindow(
                title: o.displayCustomerName ?? AppTranslation.customer,
                snippet:
                    o.displayCustomerAddressLine ??
                    o.deliveryAddress ??
                    o.customer?.address,
              ),
            ),
          );
        }
        if ((rLat == null || rLng == null || dLat == null || dLng == null) &&
            o.latitude != null &&
            o.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('order_${o.id}'),
              position: LatLng(o.latitude!, o.longitude!),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: o.displayCustomerName ?? AppTranslation.customer,
              ),
            ),
          );
        }
      }

      for (final o in state.availableOrders) {
        if (o.latitude != null && o.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId(o.id),
              position: LatLng(o.latitude!, o.longitude!),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: InfoWindow(
                title: o.displayCustomerName ?? AppTranslation.customer,
              ),
            ),
          );
        }
      }
      return markers;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ManageOrderBloc, ManageOrderState>(
          listener: (context, state) {
            if (state is ManageOrderSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.kind.localized)));
              context.read<DeliveryHomeBloc>().add(
                const LoadDeliveryHomeEvent(),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorManager.background,
        appBar: const DeliveryHomeAppBar(),
        body: BlocListener<DeliveryHomeBloc, DeliveryHomeState>(
          listenWhen: (prev, cur) => prev != cur,
          listener: (context, state) {
            _routeManager.syncAssignedRouteHistorySubscription(state);
            _routeManager.syncPlannedDrivingRoute(
              state,
              driverLat: _locationController.currentLat,
              driverLng: _locationController.currentLng,
            );
            if (state is DeliveryHomeLoaded) {
              _orderStatusWatcher.syncOrders([
                if (state.assignedOrder != null) state.assignedOrder!,
                ...state.availableOrders,
              ]);
            }
          },
          child: BlocBuilder<DeliveryHomeBloc, DeliveryHomeState>(
            builder: (context, state) {
              return RefreshIndicator(
                notificationPredicate: (ScrollNotification notification) {
                  if (!_canPullToRefreshDeliveryHome(state)) return false;
                  return notification.depth == 0;
                },
                onRefresh: () => _pullToRefreshDeliveryHome(),
                color: ColorManager.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: FakeDeliveryTrackingDemoBar(
                        order: state is DeliveryHomeLoaded
                            ? state.assignedOrder
                            : null,
                      ),
                    ),
                    if (state is DeliveryHomeLoaded &&
                        state.assignedOrder != null)
                      const DeliveryRouteLegende(),
                    SliverToBoxAdapter(
                      child: ListenableBuilder(
                        listenable: Listenable.merge([
                          _locationController,
                          _routeManager,
                        ]),
                        builder: (context, _) {
                          return DeliveryHomeMapSection(
                            currentLatitude: _locationController.currentLat,
                            currentLongitude: _locationController.currentLng,
                            simulatedPosition: di
                                .sl<FakeDeliveryTrackingController>()
                                .simulatedMapPosition,
                            markers: _buildMarkers(state),
                            routePolylines:
                                _routeManager.combinedRoutePolylines,
                            onMyLocationPressed:
                                _locationController.recenterOnCurrentLocation,
                            driverMarkerIcon: _driverMarkerIcon,
                          );
                        },
                      ),
                    ),
                    DeliveryHomeOrdersSection(
                      state: state,
                      onRetry: () => context.read<DeliveryHomeBloc>().add(
                        const LoadDeliveryHomeEvent(),
                      ),
                      onAcceptOrder: _confirmAcceptOrder,
                      onOrderTap: _onOrderTap,
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: AppHeight.s24)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

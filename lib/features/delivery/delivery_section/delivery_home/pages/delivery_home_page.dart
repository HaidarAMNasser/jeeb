import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import 'delivery_home_map_markers.dart';
import 'delivery_home_page_actions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/presentation/maps/delivery_map_marker_bitmaps.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_order_location_reporter.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_tracking_position_binding.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/fake_delivery_tracking_demo_bar.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

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

  final DeliveryHomeAutoRefreshGate _autoRefreshGate =
      DeliveryHomeAutoRefreshGate();

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
      onStatusChanged: () {
        if (!mounted) return;
        _autoRefreshGate.safeRefresh(context);
      },
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
    // Keep method to preserve listener hook; route drawing is RTDB-driven only.
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
    if (profileAfter is! ProfileLoaded) return;

    await di.sl<OrderStatusRtdbService>().ensureFirebaseAuthForDriver(
      profileAfter.user.id,
    );

    if (!mounted) return;
    final homeBloc = context.read<DeliveryHomeBloc>();
    homeBloc.add(const LoadDeliveryHomeEvent());
    _routeManager.syncAssignedRouteHistorySubscription(homeBloc.state);
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
    _locationController.removeListener(_onLocationChangedForRoutes);
    _locationController.dispose();
    _routeManager.dispose();
    _orderStatusWatcher.dispose();
    super.dispose();
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
            } else if (state is ManageOrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
                  backgroundColor: Colors.red,
                ),
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
            if (state is DeliveryHomeLoaded) {
              _orderStatusWatcher.syncOrders([
                if (state.assignedOrder != null) state.assignedOrder!,
                ...state.availableOrders,
              ]);
            }
          },
            child: BlocBuilder<ProfileBloc, ProfileState>(
            buildWhen: (prev, cur) =>
                prev.runtimeType != cur.runtimeType ||
                (prev is ProfileLoaded &&
                    cur is ProfileLoaded &&
                    prev.user != cur.user),
            builder: (context, profileState) {
              if (profileState is ProfileInitial ||
                  profileState is ProfileLoading) {
                return const Center(child: CustomCircleIndicator());
              }
              if (profileState is ProfileError) {
                return ErrorStateWidget(
                  message: profileState.message,
                  onRetry: () => _loadProfileThenHome(),
                );
              }
              return BlocBuilder<DeliveryHomeBloc, DeliveryHomeState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    notificationPredicate: (ScrollNotification notification) {
                      if (!deliveryHomeCanPullToRefresh(state)) return false;
                      return notification.depth == 0;
                    },
                    onRefresh: () => deliveryHomePullToRefresh(context),
                    color: ColorManager.primary,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (state is DeliveryHomeLoaded &&
                            state.assignedOrder != null)
                          const DeliveryRouteLegende(),
                        if (state is DeliveryHomeLoaded &&
                            state.assignedOrder != null &&
                            DeliveryOrderLocationReporter.shouldTrack(
                              OrderStatus.fromString(
                                state.assignedOrder!.status,
                              ),
                            ))
                          SliverToBoxAdapter(
                            child: FakeDeliveryTrackingDemoBar(
                              order: state.assignedOrder,
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: ListenableBuilder(
                            listenable: Listenable.merge([
                              _locationController,
                              _routeManager,
                            ]),
                            builder: (context, _) {
                              return DeliveryHomeMapSection(
                                currentLatitude:
                                    _locationController.currentLat,
                                currentLongitude:
                                    _locationController.currentLng,
                                markers: buildDeliveryHomeMapMarkers(
                                  state,
                                  pickupMarkerIcon: _pickupMarkerIcon,
                                  dropoffMarkerIcon: _dropoffMarkerIcon,
                                ),
                                routePolylines:
                                    _routeManager.combinedRoutePolylines,
                                onMyLocationPressed: _locationController
                                    .recenterOnCurrentLocation,
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
                          onAcceptOrder: (order) =>
                              deliveryHomeConfirmAcceptOrder(context, order),
                          onOrderTap: (order) =>
                              deliveryHomeOpenOrderDetails(context, order),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: AppHeight.s24),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

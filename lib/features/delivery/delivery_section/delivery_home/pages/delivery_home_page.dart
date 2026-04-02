import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_service.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_home_app_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_card.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_home_map.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';

import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/manage_order_success_message.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/widgets/accept_delivery_estimated_time_dialog.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/searching%20cards/delivery_searching_order_card.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  double? _currentLat;
  double? _currentLng;
  StreamSubscription<Position>? _locationSubscription;
  DateTime? _lastAutoRefreshAt;
  static const Duration _autoRefreshCooldown = Duration(seconds: 8);

  final Map<String, StreamSubscription<String?>> _statusSubs = {};
  final Map<String, String?> _lastKnownStatus = {};

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    context.read<DeliveryHomeBloc>().add(const LoadDeliveryHomeEvent());
    _ensureProfileLoaded();
  }

  void _ensureProfileLoaded() {
    final profileBloc = context.read<ProfileBloc>();
    final s = profileBloc.state;
    if (s is ProfileLoaded || s is ProfileLoading) return;
    profileBloc.add(const GetProfile());
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _cancelAllStatusSubs();
    super.dispose();
  }

  void _watchOrderStatuses(List<OrderEntity> orders) {
    final activeIds = orders.map((o) => o.id).toSet();

    // Cancel subs for orders no longer visible.
    _statusSubs.keys
        .where((id) => !activeIds.contains(id))
        .toList()
        .forEach((id) {
      _statusSubs.remove(id)?.cancel();
      _lastKnownStatus.remove(id);
    });

    // Start subs for new orders.
    for (final order in orders) {
      if (_statusSubs.containsKey(order.id)) continue;
      _lastKnownStatus[order.id] = order.status;
      _statusSubs[order.id] = di
          .sl<OrderStatusRtdbService>()
          .watchOrderStatusWire(order.id)
          .listen((wire) {
        if (!mounted || wire == null || wire.trim().isEmpty) return;
        final prev = _lastKnownStatus[order.id];
        final normalizedWire = wire.trim().toUpperCase();
        final normalizedPrev = prev?.trim().toUpperCase();
        if (normalizedWire != normalizedPrev) {
          _lastKnownStatus[order.id] = wire;
          _safeAutoRefreshHome();
        }
      }, onError: (_) {});
    }
  }

  void _cancelAllStatusSubs() {
    for (final sub in _statusSubs.values) {
      sub.cancel();
    }
    _statusSubs.clear();
    _lastKnownStatus.clear();
  }

  Future<void> _startLocationUpdates() async {
    try {
      _locationSubscription = LocationService.instance
          .getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          )
          .listen(
            (position) {
              if (mounted) {
                setState(() {
                  _currentLat = position.latitude;
                  _currentLng = position.longitude;
                });
              }
            },
            onError: (_) {
              // Permission denied / stream failure: ignore and keep home usable.
            },
          );
    } catch (_) {
      // Permission handled in helper
    }
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
    final now = DateTime.now();
    final last = _lastAutoRefreshAt;
    if (last != null && now.difference(last) < _autoRefreshCooldown) return;
    if (context.read<DeliveryHomeBloc>().state is DeliveryHomeLoading) return;
    _lastAutoRefreshAt = now;
    context.read<DeliveryHomeBloc>().add(const RefreshDeliveryHomeEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ManageOrderBloc, ManageOrderState>(
          listener: (context, state) {
            if (state is ManageOrderSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.kind.localized)),
              );
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
        body: BlocBuilder<DeliveryHomeBloc, DeliveryHomeState>(
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppPadding.p16),
                      child: DeliveryHomeMap(
                        latitude: _currentLat,
                        longitude: _currentLng,
                        markers: _buildMarkers(state),
                      ),
                    ),
                  ),
                  _buildContent(state),
                  SliverToBoxAdapter(child: SizedBox(height: AppHeight.s24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(DeliveryHomeState state) {
    return BlocStateHandler<DeliveryHomeBloc, DeliveryHomeState>(
      bloc: context.read<DeliveryHomeBloc>(),
      isLoading: (s) => s is DeliveryHomeLoading || s is DeliveryHomeInitial,
      loadingWidget: const SliverToBoxAdapter(child: CustomCircleIndicator()),
      isError: (s) => s is DeliveryHomeError,
      getErrorMessage: (s) => (s as DeliveryHomeError).message,
      errorBuilder: (context, message, onRetry) => SliverToBoxAdapter(
        child: ErrorStateWidget(message: message, onRetry: onRetry),
      ),
      isSuccess: (s) => s is DeliveryHomeLoaded,
      successBuilder: (context, s) {
        final loadedState = s as DeliveryHomeLoaded;

        // Start realtime status listeners for searching orders only.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _watchOrderStatuses(loadedState.availableOrders);
        });

        // Case 1: Assigned Order Exists
        if (loadedState.assignedOrder != null) {
          return SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(AppTranslation.activeOrders),
                DeliveryOrderCard(
                  order: loadedState.assignedOrder!,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.deliveryOrderDetails,
                      arguments: {'orderId': loadedState.assignedOrder!.id},
                    );
                  },
                ),
              ],
            ),
          );
        }

        // Case 2: Available Orders
        if (loadedState.availableOrders.isNotEmpty) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: _buildSectionHeader(AppTranslation.searchOrders),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => DeliverySearchingOrderCard(
                    key: ValueKey(
                      'searching_${loadedState.availableOrders[index].id}',
                    ),
                    order: loadedState.availableOrders[index],
                    onTimerExpired: null,
                    onTap: () {
                      final o = loadedState.availableOrders[index];
                      if (OrderStatus.fromString(o.status) ==
                          OrderStatus.searching) {
                        return;
                      }
                      Navigator.pushNamed(
                        context,
                        Routes.deliveryOrderDetails,
                        arguments: {
                          'orderId': o.id,
                        },
                      );
                    },
                    onAccept: () =>
                        _confirmAcceptOrder(loadedState.availableOrders[index]),
                  ),
                  childCount: loadedState.availableOrders.length,
                ),
              ),
            ],
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppPadding.p16,
        0,
        AppPadding.p16,
        AppPadding.p16,
      ),
      child: CustomText(
        text: title,
        textStyle: getBoldStyle(
          fontSize: AppFontSize.s20,
          color: ColorManager.titlesColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(top: AppHeight.s50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_meals_outlined,
                size: AppSize.s60,
                color: ColorManager.textSecondary.withOpacity(0.5),
              ),
              SizedBox(height: AppHeight.s16),
              CustomText(
                text: AppTranslation.noActiveOrders,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAcceptOrder(OrderEntity order) async {
    final minutes = await AcceptDeliveryEstimatedTimeDialog.show(context);
    if (!mounted || minutes == null) return;
    context.read<ManageOrderBloc>().add(
      AcceptDeliveryEvent(id: order.id, deliveryTime: minutes),
    );
  }

  Set<Marker> _buildMarkers(DeliveryHomeState state) {
    if (state is DeliveryHomeLoaded) {
      final Set<Marker> markers = {};

      // Show assigned order marker if exists
      if (state.assignedOrder != null) {
        final o = state.assignedOrder!;
        if (o.latitude != null && o.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId(o.id),
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

      // Show available orders markers
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
}

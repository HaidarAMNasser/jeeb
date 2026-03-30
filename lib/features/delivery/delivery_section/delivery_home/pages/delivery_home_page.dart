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

import 'package:jeeb_app/core/presentation/widgets/confirmation_dialog.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_available_order_card.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  double? _currentLat;
  double? _currentLng;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    context.read<DeliveryHomeBloc>().add(const LoadDeliveryHomeEvent());
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
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
          .listen((position) {
            if (mounted) {
              setState(() {
                _currentLat = position.latitude;
                _currentLng = position.longitude;
              });
            }
          });
    } catch (_) {
      // Permission handled in helper
    }
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
              ).showSnackBar(SnackBar(content: Text(state.message)));
              // Refresh home data
              context.read<DeliveryHomeBloc>().add(
                const LoadDeliveryHomeEvent(),
              );
              // Navigate to details if accepted
              if (state.message.toLowerCase().contains('accepted') ||
                  state.message.contains('تم قبول')) {
                // We'll need the order ID from the event if possible,
                // but since we don't have it in the state, we can use a callback
                // or just rely on the UI refresh for now.
              }
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
              onRefresh: () async {
                context.read<DeliveryHomeBloc>().add(
                  const RefreshDeliveryHomeEvent(),
                );
              },
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
                  (context, index) => DeliveryAvailableOrderCard(
                    order: loadedState.availableOrders[index],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.deliveryOrderDetails,
                        arguments: {
                          'orderId': loadedState.availableOrders[index].id,
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

  void _confirmAcceptOrder(OrderEntity order) {
    ConfirmationDialog.show(
      context: context,
      title: AppTranslation.confirmDelivery,
      onConfirm: () {
        context.read<ManageOrderBloc>().add(
          AcceptDeliveryEvent(id: order.id, deliveryTime: 30),
        );
        // Navigation to details happens after success listener in build
      },
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
                title: o.customerName ?? AppTranslation.customer,
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
                title: o.customerName ?? AppTranslation.customer,
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

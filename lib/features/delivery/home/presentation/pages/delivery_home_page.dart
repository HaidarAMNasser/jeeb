import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_permission_helper.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_home_app_bar.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_home_map.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_order_card.dart';
import 'package:jeeb_app/features/delivery/home/presentation/bloc/delivery_home_bloc.dart';
import 'package:latlong2/latlong.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  double? _currentLat;
  double? _currentLng;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    context.read<DeliveryHomeBloc>().add(const LoadDeliveryHomeEvent());
  }

  Future<void> _requestLocationPermission() async {
    final result = await LocationPermissionHelper.requestAndGetPosition();
    if (mounted && result.latitude != null && result.longitude != null) {
      setState(() {
        _currentLat = result.latitude;
        _currentLng = result.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      key: ValueKey('map_$_currentLat$_currentLng'),
                      latitude: _currentLat,
                      longitude: _currentLng,
                      markers: _buildMarkers(state),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: AppTranslation.activeOrders,
                          textStyle: getBoldStyle(
                            fontSize: AppFontSize.s20,
                            color: ColorManager.titlesColor,
                          ),
                        ),
                        SizedBox(height: AppHeight.s16),
                      ],
                    ),
                  ),
                ),
                _buildOrdersList(state),
                SliverToBoxAdapter(child: SizedBox(height: AppHeight.s24)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Marker> _buildMarkers(DeliveryHomeState state) {
    if (state is DeliveryHomeLoaded && state.orders.isNotEmpty) {
      // Driver can only have one active order, so show its marker
      final o = state.orders.first;
      if (o.latitude != null && o.longitude != null) {
        return [
          Marker(
            point: LatLng(o.latitude!, o.longitude!),
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ];
      }
    }
    return [];
  }

  Widget _buildOrdersList(DeliveryHomeState state) {
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
      isEmpty: (s) => s is DeliveryHomeLoaded && s.orders.isEmpty,
      emptyBuilder: (context) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: AppHeight.s50),
            child: Column(
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
      ),
      getRetryCallback: (_) =>
          () => context.read<DeliveryHomeBloc>().add(
            const LoadDeliveryHomeEvent(),
          ),
      successBuilder: (context, s) {
        final loadedState = s as DeliveryHomeLoaded;
        if (loadedState.orders.isEmpty)
          return const SliverToBoxAdapter(child: SizedBox.shrink());

        // Driver can only have one order
        final activeOrder = loadedState.orders.first;

        return SliverToBoxAdapter(
          child: DeliveryOrderCard(
            order: activeOrder,
            onTap: () {
              // Navigate to order details if needed
            },
          ),
        );
      },
    );
  }
}

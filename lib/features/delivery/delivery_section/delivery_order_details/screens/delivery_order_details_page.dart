import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_header.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_price_section.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_home_map.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/delivery_order_details_lines_section.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/delivery_order_details_restaurant_section.dart';
import '../widgets/order_details_status_badge.dart';
import '../widgets/order_details_action_buttons.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryOrderDetailsPage extends StatelessWidget {
  final String orderId;

  const DeliveryOrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              di.sl<OrderDetailsBloc>()..add(GetOrderDetailsEvent(orderId)),
        ),
        BlocProvider(create: (context) => di.sl<ManageOrderBloc>()),
      ],
      child: Scaffold(
        backgroundColor: ColorManager.background,
        appBar: CustomAppBar(title: AppTranslation.orderDetails),
        body: BlocListener<ManageOrderBloc, ManageOrderState>(
          listener: (context, state) {
            if (state is ManageOrderSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              // Refresh order details after successful action
              context.read<OrderDetailsBloc>().add(
                GetOrderDetailsEvent(orderId),
              );
            } else if (state is ManageOrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<OrderDetailsBloc, OrderDetailsState>(
            builder: (context, state) {
              return BlocStateHandler<OrderDetailsBloc, OrderDetailsState>(
                bloc: context.read<OrderDetailsBloc>(),
                isLoading: (s) => s is OrderDetailsLoading,
                loadingWidget: const Center(child: CustomCircleIndicator()),
                isError: (s) => s is OrderDetailsError,
                getErrorMessage: (s) => (s as OrderDetailsError).message,
                errorBuilder: (context, message, onRetry) =>
                    ErrorStateWidget(message: message, onRetry: onRetry),
                isSuccess: (s) => s is OrderDetailsLoaded,
                successBuilder: (context, s) {
                  final order = (s as OrderDetailsLoaded).order;
                  return _buildContent(context, order, orderId);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderEntity order,
    String orderId,
  ) {
    final status = OrderStatus.fromString(order.status);
    void refreshDetails() {
      context.read<OrderDetailsBloc>().add(GetOrderDetailsEvent(orderId));
    }

    final productsSumMinor = order.products.fold<int>(
      0,
      (s, p) => s + p.displayPrice,
    );
    final feeMinor = (order.deliveryFee ?? 0).round();
    final itemsMinor = order.itemsTotal != null
        ? order.itemsTotal!.round()
        : (order.itemLines.isEmpty
            ? productsSumMinor
            : order.itemLines.fold<int>(
                0,
                (s, e) => s + e.lineTotalMinor,
              ));
    final offersMinor = order.offersTotal?.round() ?? 0;
    final totalMinor = order.totalPrice != null
        ? order.totalPrice!.round()
        : productsSumMinor + feeMinor;
    final fromOwnerRestaurant = order.owner?.restaurantName?.trim();
    final restaurantName = (fromOwnerRestaurant != null &&
            fromOwnerRestaurant.isNotEmpty)
        ? fromOwnerRestaurant
        : (order.products.isNotEmpty
            ? order.products.first.merchantName ??
                AppTranslation.restaurantName
            : AppTranslation.restaurantName);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppPadding.p25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Badge
          Padding(
            padding: EdgeInsets.all(AppPadding.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OrderDetailsStatusBadge(status: status),
                CustomText(
                  text: '${AppTranslation.orderNumber}${order.id}',
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Map
          DeliveryHomeMap(
            latitude: order.latitude,
            longitude: order.longitude,
            markers: {
              if (order.latitude != null && order.longitude != null)
                Marker(
                  markerId: MarkerId(order.id),
                  position: LatLng(order.latitude!, order.longitude!),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                  infoWindow: InfoWindow(
                    title: order.displayCustomerName ?? AppTranslation.customer,
                    snippet: order.displayCustomerAddressLine ??
                        order.deliveryAddress,
                  ),
                ),
            },
          ),

          SizedBox(height: AppHeight.s24),

          // Sections
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionCard(
                  child: DeliveryOrderHeader(
                    recipientName:
                        order.displayCustomerName ?? AppTranslation.customer,
                    recipientAddress:
                        order.displayCustomerAddressLine ??
                            order.deliveryAddress ??
                            '',
                    totalPrice: totalMinor,
                  ),
                ),
                SizedBox(height: AppHeight.s16),
                _buildSectionCard(
                  child: DeliveryOrderDetailsRestaurantSection(
                    order: order,
                    restaurantName: restaurantName,
                    onMealPrepElapsed: refreshDetails,
                  ),
                ),
                SizedBox(height: AppHeight.s16),
                _buildSectionCard(
                  child: DeliveryOrderDetailsLinesSection(
                    itemLines: order.itemLines,
                    offerBundles: order.offerBundles,
                    fallbackProducts: order.products,
                  ),
                ),
                SizedBox(height: AppHeight.s16),
                _buildSectionCard(
                  child: DeliveryOrderPriceSection(
                    itemsTotal: itemsMinor,
                    offersTotal: offersMinor,
                    deliveryFee: feeMinor,
                    totalAmount: totalMinor,
                    detailsTotalsOrder: true,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppHeight.s32),

          // Action Buttons
          OrderDetailsActionButtons(
            order: order,
            status: status,
            onRefreshOrder: refreshDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.primaryDark,
        borderRadius: BorderRadius.circular(AppSize.s20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

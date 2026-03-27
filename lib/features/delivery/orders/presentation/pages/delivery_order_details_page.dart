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
import 'package:url_launcher/url_launcher.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_home_map.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_order_header.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_order_merchant.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_order_items_list.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_order_price_section.dart';
import 'package:jeeb_app/features/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

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
                  return _buildContent(context, order);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrderEntity order) {
    final status = OrderStatus.fromString(order.status);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppPadding.p25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Padding(
            padding: EdgeInsets.all(AppPadding.p16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                CustomText(
                  text: 'Order #${order.id}',
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
            key: ValueKey('detail_map_${order.latitude}_${order.longitude}'),
            latitude: order.latitude,
            longitude: order.longitude,
            markers: [
              if (order.latitude != null && order.longitude != null)
                Marker(
                  point: LatLng(order.latitude!, order.longitude!),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorManager.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: AppHeight.s24),

          // Sections
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
            child: Column(
              children: [
                _buildSectionCard(
                  child: DeliveryOrderHeader(
                    recipientName:
                        order.customerName ?? AppTranslation.customer,
                    recipientAddress: order.deliveryAddress ?? '',
                    totalPrice: (order.totalPrice ?? 0).toInt(),
                  ),
                ),
                SizedBox(height: AppHeight.s16),
                _buildSectionCard(
                  child: DeliveryOrderMerchant(
                    restaurantName: order.products.isNotEmpty
                        ? order.products.first.merchantName ??
                              AppTranslation.restaurantName
                        : AppTranslation.restaurantName,
                    preparationDuration: Duration(
                      minutes: order.preparationTime ?? 15,
                    ),
                  ),
                ),
                SizedBox(height: AppHeight.s16),
                _buildSectionCard(
                  child: DeliveryOrderItemsList(products: order.products),
                ),
                SizedBox(height: AppHeight.s16),
                _buildSectionCard(
                  child: DeliveryOrderPriceSection(
                    deliveryFee: (order.deliveryFee ?? 0).toInt(),
                    deliveryEarning: (order.deliveryEarning ?? 0).toInt(),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppHeight.s32),

          // Action Buttons
          _buildActionButtons(context, order, status),
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

  Widget _buildStatusBadge(OrderStatus status) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSize.s8),
        border: Border.all(color: status.color.withOpacity(0.5)),
      ),
      child: CustomText(
        text: status.displayLabel,
        textStyle: getBoldStyle(fontSize: AppFontSize.s12, color: status.color),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    OrderEntity order,
    OrderStatus status,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: BlocBuilder<ManageOrderBloc, ManageOrderState>(
        builder: (context, state) {
          final isLoading = state is ManageOrderLoading;

          return Column(
            children: [
              if (order.customerPhone != null &&
                  order.customerPhone!.isNotEmpty) ...[
                _buildButton(
                  text: 'Call Customer (${order.customerPhone})',
                  color: Colors.blueGrey,
                  icon: Icons.phone,
                  isLoading: false,
                  onPressed: () =>
                      launchUrl(Uri.parse('tel:${order.customerPhone}')),
                ),
                SizedBox(height: AppHeight.s12),
              ],
              if (status == OrderStatus.readyForPickup)
                _buildButton(
                  text: 'Accept Delivery',
                  color: ColorManager.primary,
                  icon: Icons.check_circle_outline,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    AcceptDeliveryEvent(id: order.id, deliveryTime: 30),
                  ),
                )
              else if (status == OrderStatus.assigned) ...[
                _buildButton(
                  text: 'Confirm Pickup',
                  color: Colors.blue,
                  icon: Icons.shopping_bag_outlined,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    ConfirmPickupEvent(id: order.id, reason: 'Picked up'),
                  ),
                ),
                SizedBox(height: AppHeight.s12),
                _buildButton(
                  text: 'Reject Delivery',
                  color: Colors.red,
                  icon: Icons.cancel_outlined,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    RejectDeliveryEvent(
                      id: order.id,
                      reason: 'Unable to deliver',
                    ),
                  ),
                ),
              ] else if (status == OrderStatus.pickedUp)
                _buildButton(
                  text: 'Mark as Delivered',
                  color: Colors.green,
                  icon: Icons.delivery_dining,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    MarkAsDeliveredEvent(
                      id: order.id,
                      reason: 'Handed to customer',
                      lat: 0,
                      lng: 0,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppHeight.s50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.s12),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    SizedBox(width: AppWidth.s8),
                  ],
                  CustomText(
                    text: text,
                    textStyle: getBoldStyle(
                      fontSize: AppFontSize.s16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

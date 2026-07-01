import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/classes/user_roles.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
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
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/map_details/delivery_order_details_route_map.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/delivery_order_details_lines_section.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/delivery_order_details_restaurant_section.dart';
import '../widgets/order_details_status_badge.dart';
import '../widgets/order_details_action_buttons.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/manage_order_success_message.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_order_location_reporter.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/fake_delivery_tracking_demo_bar.dart';

class DeliveryOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const DeliveryOrderDetailsPage({super.key, required this.orderId});

  @override
  State<DeliveryOrderDetailsPage> createState() =>
      _DeliveryOrderDetailsPageState();
}

class _DeliveryOrderDetailsPageState extends State<DeliveryOrderDetailsPage> {
  DateTime? _lastAutoRefreshAt;
  static const Duration _autoRefreshCooldown = Duration(seconds: 8);
  Future<bool>? _isDeliveryDriver;

  void _safeRefreshDetails(BuildContext context) {
    final now = DateTime.now();
    final last = _lastAutoRefreshAt;
    if (last != null && now.difference(last) < _autoRefreshCooldown) return;
    if (context.read<OrderDetailsBloc>().state is OrderDetailsLoading) return;
    _lastAutoRefreshAt = now;
    context.read<OrderDetailsBloc>().add(GetOrderDetailsEvent(widget.orderId));
  }

  @override
  void initState() {
    super.initState();
    _isDeliveryDriver = _loadDeliveryRole(di.sl<StorageService>());
  }

  Future<bool> _loadDeliveryRole(StorageService storage) async {
    final r = await storage.getUserRole();
    if (r == null || r.isEmpty) return false;
    final u = r.toUpperCase();
    return u == 'DELIVERY' || r == UserRoles.deliveryMan.name;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              di.sl<OrderDetailsBloc>()
                ..add(GetOrderDetailsEvent(widget.orderId)),
        ),
      ],
        child: Scaffold(
        backgroundColor: ColorManager.background,
        appBar: CustomAppBar(
          title: AppTranslation.orderDetails,
          actions: [
            // BlocBuilder<OrderDetailsBloc, OrderDetailsState>(
            //   builder: (context, state) {
            //     if (state is! OrderDetailsLoaded) {
            //       return const SizedBox.shrink();
            //     }
            //     final order = state.order;
            //     final st = OrderStatus.fromString(order.status);
            //     if (st != OrderStatus.delivered) {
            //       return const SizedBox.shrink();
            //     }
            //     return FutureBuilder<bool>(
            //       future: _isDeliveryDriver,
            //       builder: (context, snap) {
            //         if (snap.data != true) return const SizedBox.shrink();
            //         return DeliveryPayAdminMenuButton(
            //           order: order,
            //           pageOrders: [order],
            //           entryKind: DeliveryPayAdminEntryKind.orderDetails,
            //           payAdminBloc: context.read<PayAdminBloc>(),
            //           onAfterPaySuccess: () {
            //             _safeRefreshDetails(context);
            //             di.sl<DeliveryPaySelectionController>().completedTabReloadTick.value++;
            //           },
            //         );
            //       },
            //     );
            //   },
            // ),
          ],
        ),
        body: BlocListener<ManageOrderBloc, ManageOrderState>(
          listener: (context, state) {
            if (state is ManageOrderSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.kind.localized)),
              );
              _safeRefreshDetails(context);
              final homeBloc = di.sl<DeliveryHomeBloc>();
              if (!homeBloc.isClosed) {
                homeBloc.add(const LoadDeliveryHomeEvent());
              }
            } else if (state is ManageOrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message.tr()),
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
    void refreshDetails() {
      _safeRefreshDetails(context);
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
              : order.itemLines.fold<int>(0, (s, e) => s + e.lineTotalMinor));
    final offersMinor = order.offersTotal?.round() ?? 0;
    final totalMinor = order.totalPrice != null
        ? order.totalPrice!.round()
        : productsSumMinor + feeMinor;
    final fromOwnerRestaurant = order.owner?.restaurantName?.trim();
    final restaurantName =
        (fromOwnerRestaurant != null && fromOwnerRestaurant.isNotEmpty)
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
                    color: ColorManager.defaultWhite,
                  ),
                ),
              ],
            ),
          ),

          if (DeliveryOrderLocationReporter.shouldTrack(status))
            FakeDeliveryTrackingDemoBar(order: order),

          // Map: restaurant vs customer drop-off + route
          DeliveryOrderDetailsRouteMap(
            key: ValueKey(
              '${order.id}_${order.restaurantLatitude}_${order.restaurantLongitude}_${order.dropoffLatitude}_${order.dropoffLongitude}',
            ),
            order: order,
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
                    customerPhone: order.resolvedCustomerPhone,
                  ),
                ),
                SizedBox(height: AppHeight.s16),
                _buildSectionCard(
                  child: DeliveryOrderDetailsRestaurantSection(
                    order: order,
                    restaurantName: restaurantName,
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
          DeliveryOrderActionButtons(
            order: order,
            status: status,
            onRefreshOrder: refreshDetails,
            padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
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

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/common/utils/order_status_step_index.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_date_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_delivery_man_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_delivery_map_preview.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_header_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_location_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_people_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_products_section.dart';
class OrderDetailsContent extends StatelessWidget {
  final OrderEntity order;

  const OrderDetailsContent({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final routeStatus = OrderStatus.fromString(order.status);
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status
          OrderHeaderCard(order: order),
          if (!orderStatusIsTerminal(routeStatus)) ...[
            SizedBox(height: AppHeight.s12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: AppPadding.p14,
                    horizontal: AppPadding.p16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r14),
                  ),
                ),
                onPressed: () {
                  AppRouter.navigateTo(
                    context,
                    Routes.orderStatus,
                    arguments: {
                      'orderId': order.id,
                      'initialStatus': order.status,
                      if (order.latitude != null)
                        'deliveryLatitude': order.latitude,
                      if (order.longitude != null)
                        'deliveryLongitude': order.longitude,
                    },
                  );
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(AppTranslation.orderTrackOrderCta),
              ),
            ),
          ],
          SizedBox(height: AppHeight.s16),

          if (OrderStatus.fromString(order.status) == OrderStatus.onTheWay) ...[
            OrderDeliveryMapSection(
              mapBadgeLabel: AppTranslation.orderDeliveryMapBadge,
              deliveryStatus: routeStatus,
              latitude: order.latitude,
              longitude: order.longitude,
            ),
            SizedBox(height: AppHeight.s16),
          ],

          // Date
          if (order.date != null) ...[
            OrderDateCard(date: order.date!),
            SizedBox(height: AppHeight.s16),
          ],

          // Number of People
          if (order.numberOfPeople != null) ...[
            OrderPeopleCard(numberOfPeople: order.numberOfPeople!),
            SizedBox(height: AppHeight.s16),
          ],
          // Products
          OrderProductsSection(products: order.products),

          // Delivery Man
          if (order.deliveryMan != null) ...[
            OrderDeliveryManCard(deliveryMan: order.deliveryMan!),
            SizedBox(height: AppHeight.s16),
          ], // Location
          if (order.latitude != null && order.longitude != null) ...[
            OrderLocationCard(
              latitude: order.latitude!,
              longitude: order.longitude!,
            ),
            SizedBox(height: AppHeight.s16),
          ],
        ],
      ),
    );
  }
}

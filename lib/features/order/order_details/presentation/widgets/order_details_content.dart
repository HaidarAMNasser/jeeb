import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_date_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_delivery_man_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_header_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_location_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_people_card.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_products_section.dart';
class OrderDetailsContent extends StatelessWidget {
  final OrderEntity order;

  const OrderDetailsContent({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status
          OrderHeaderCard(order: order),
          SizedBox(height: AppHeight.s16),

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

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'delivery_order_header.dart';
import 'delivery_order_merchant.dart';
import 'delivery_order_items_list.dart';
import 'delivery_order_price_section.dart';

class DeliveryOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  const DeliveryOrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Calculate total price from products
    final totalPrice = order.products.fold<int>(
      0,
      (sum, p) => sum + p.displayPrice,
    );

    // Merchant (Restaurant) info
    final restaurantName = order.products.isNotEmpty
        ? order.products.first.merchantName ?? AppTranslation.restaurantName
        : AppTranslation.restaurantName;

    // Recipient (Customer) info
    final recipientName =
        order.customerName ??
        (order.deliveryMan?.name ?? AppTranslation.customer);
    final recipientAddress =
        order.deliveryAddress ?? (order.deliveryMan?.cityName ?? '');

    // Get delivery fees from order entity
    final deliveryFee = (order.deliveryFee ?? 0).toInt();
    final deliveryEarning = (order.deliveryEarning ?? 0).toInt();
    final preparationMinutes = order.preparationTime ?? 15;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppPadding.p16),
        padding: EdgeInsets.all(AppPadding.p20),
        decoration: BoxDecoration(
          color: ColorManager.primaryDark,
          borderRadius: BorderRadius.circular(AppSize.s24),
          border: Border.all(
            color: ColorManager.primary.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeliveryOrderHeader(
              recipientName: recipientName,
              recipientAddress: recipientAddress,
              totalPrice:
                  (order.totalPrice ?? (totalPrice + deliveryFee).toDouble())
                      .toInt(),
            ),
            SizedBox(height: AppHeight.s20),
            DeliveryOrderMerchant(
              restaurantName: restaurantName,
              preparationDuration: Duration(minutes: preparationMinutes),
            ),
            SizedBox(height: AppHeight.s24),
            DeliveryOrderItemsList(products: order.products),
            SizedBox(height: AppHeight.s12),
            DeliveryOrderPriceSection(
              deliveryFee: deliveryFee,
              deliveryEarning: deliveryEarning,
            ),
            SizedBox(height: AppHeight.s16),
            _DeliveryOrderFooter(orderId: order.id, status: order.status),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOrderFooter extends StatelessWidget {
  final String orderId;
  final String? status;

  const _DeliveryOrderFooter({required this.orderId, this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: status ?? '',
          textStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s10,
            color: ColorManager.primary.withOpacity(0.7),
          ),
        ),
        CustomText(
          text: 'Order #$orderId',
          textStyle: TextStyle(
            fontSize: AppFontSize.s10,
            color: ColorManager.textSecondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

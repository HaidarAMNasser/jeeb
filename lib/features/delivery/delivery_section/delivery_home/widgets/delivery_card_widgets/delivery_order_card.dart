import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/order_details_action_buttons.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'delivery_order_card_top_bar.dart';
import 'delivery_order_header.dart';
import 'delivery_order_merchant.dart';
import '../delivery_order_items_list.dart';
import 'delivery_order_price_section.dart';

class DeliveryOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  const DeliveryOrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromString(order.status);
    final productsSumMinor = order.products.fold<int>(
      0,
      (sum, p) => sum + p.displayPrice,
    );
    final itemsMinor = order.itemsTotal != null
        ? order.itemsTotal!.round()
        : productsSumMinor;
    final offersMinor = order.offersTotal?.round() ?? 0;
    final deliveryFeeMinor = (order.deliveryFee ?? 0).round();
    final totalMinor = order.totalPrice != null
        ? order.totalPrice!.round()
        : (productsSumMinor + deliveryFeeMinor);

    final fromOwner = order.owner?.restaurantName?.trim();
    final restaurantName = (fromOwner != null && fromOwner.isNotEmpty)
        ? fromOwner
        : (order.products.isNotEmpty
              ? order.products.first.merchantName ??
                    AppTranslation.restaurantName
              : AppTranslation.restaurantName);

    final recipientName =
        order.displayCustomerName ??
        (order.deliveryMan?.name ?? AppTranslation.customer);
    final recipientAddress = order.displayCustomerAddressWithoutPhone;

    final preparationMinutes =
        order.mealPreparationMinutes ?? order.preparationTime;
    final showPreparationTime =
        status == OrderStatus.assigned &&
        preparationMinutes != null &&
        preparationMinutes > 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: Material(
        color: ColorManager.primaryDark,
        borderRadius: BorderRadius.circular(AppSize.s24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.s24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.s24),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSize.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppPadding.p18,
                      AppPadding.p16,
                      AppPadding.p18,
                      AppPadding.p12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DeliveryOrderCardTopBar(
                          orderId: order.id,
                          initialStatusWire: order.status,
                        ),
                        SizedBox(height: AppHeight.s14),
                        DeliveryOrderHeader(
                          recipientName: recipientName,
                          recipientAddress: recipientAddress,
                          totalPrice: totalMinor,
                          showPriceTag: false,
                        ),
                        SizedBox(height: AppHeight.s20),
                        DeliveryOrderMerchant(
                          restaurantName: restaurantName,
                          pickupAddressLine:
                              order.displayRestaurantPickupAddressLine,
                          preparationMinutes: preparationMinutes,
                          showPreparationTime: showPreparationTime,
                        ),
                        SizedBox(height: AppHeight.s20),
                        DeliveryOrderItemsList(
                          products: order.products,
                          lineItems: order.displayLineProducts,
                        ),
                        SizedBox(height: AppHeight.s10),
                        DeliveryOrderPriceSection(
                          itemsTotal: itemsMinor,
                          offersTotal: offersMinor,
                          deliveryFee: deliveryFeeMinor,
                          totalAmount: totalMinor,
                          showGrandTotal: true,
                          compactRows: true,
                          capstoneGrandTotal: true,
                        ),
                      ],
                    ),
                  ),
                  DeliveryOrderActionButtons(
                    order: order,
                    status: status,
                    padding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

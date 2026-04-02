import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/order_details_action_buttons.dart';
import 'delivery_order_header.dart';
import 'delivery_order_merchant.dart';
import '../delivery_order_items_list.dart';
import 'delivery_order_price_section.dart';
import 'delivery_merchant_phone_row.dart';
import 'delivery_order_card_footer.dart';

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
    final itemsMinor =
        order.itemsTotal != null ? order.itemsTotal!.round() : productsSumMinor;
    final offersMinor = order.offersTotal?.round() ?? 0;
    final deliveryFeeMinor = (order.deliveryFee ?? 0).round();
    final totalMinor = order.totalPrice != null
        ? order.totalPrice!.round()
        : (productsSumMinor + deliveryFeeMinor);

    // Merchant (Restaurant) info — prefer API `owner.restaurantName`
    final fromOwner = order.owner?.restaurantName?.trim();
    final restaurantName = (fromOwner != null && fromOwner.isNotEmpty)
        ? fromOwner
        : (order.products.isNotEmpty
            ? order.products.first.merchantName ?? AppTranslation.restaurantName
            : AppTranslation.restaurantName);

    // Recipient (Customer) info
    final recipientName = order.displayCustomerName ??
        (order.deliveryMan?.name ?? AppTranslation.customer);
    final recipientAddress = order.displayCustomerAddressLine ?? '';

    final preparationMinutes = order.mealPreparationMinutes ?? order.preparationTime;
    final showPreparationTimer =
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSize.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(AppPadding.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DeliveryOrderHeader(
                          recipientName: recipientName,
                          recipientAddress: recipientAddress,
                          totalPrice: totalMinor,
                        ),
                        SizedBox(height: AppHeight.s20),
                        DeliveryOrderMerchant(
                          restaurantName: restaurantName,
                          preparationDuration: Duration(
                            minutes: preparationMinutes ?? 0,
                          ),
                          showPreparationTimer: showPreparationTimer,
                        ),
                        SizedBox(height: AppHeight.s24),
                        DeliveryOrderItemsList(products: order.products),
                        SizedBox(height: AppHeight.s12),
                        DeliveryOrderPriceSection(
                          itemsTotal: itemsMinor,
                          offersTotal: offersMinor,
                          deliveryFee: deliveryFeeMinor,
                          totalAmount: totalMinor,
                        ),
                        if (order.merchantPhone != null &&
                            order.merchantPhone!.isNotEmpty &&
                            order.hideMerchantPhone != true) ...[
                          SizedBox(height: AppHeight.s16),
                          DeliveryMerchantPhoneRow(phone: order.merchantPhone!),
                        ],
                        SizedBox(height: AppHeight.s16),
                        DeliveryOrderCardFooter(
                          orderId: order.id,
                          status: order.status,
                        ),
                      ],
                    ),
                  ),
                  // Driver Action Section (In-card details)
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

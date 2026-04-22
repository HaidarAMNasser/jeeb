import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/common/utils/order_status_step_index.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_client_driver_contact_card.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_client_support_phone_row.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_delivery_man_card.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_products_section.dart';

class OrderDetailsContent extends StatelessWidget {
  final OrderEntity order;
  final String? supportPhone;

  const OrderDetailsContent({
    super.key,
    required this.order,
    this.supportPhone,
  });

  @override
  Widget build(BuildContext context) {
    final routeStatus = OrderStatus.fromString(order.status);
    final restaurant = order.displayRestaurantName;
    final dm = order.deliveryMan;
    final driverPhoneTrimmed = dm?.phone.trim() ?? '';
    final supportTrimmed = supportPhone?.trim() ?? '';
    final showSupportRow =
        orderStatusShowsDriverContact(routeStatus) && supportTrimmed.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (restaurant != null && restaurant.isNotEmpty) ...[
            CustomText(
              text: restaurant,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.primary,
              ),
              maxLines: 3,
              textOverflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppHeight.s12),
          ],
          if (order.status != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p8,
                vertical: AppPadding.p4,
              ),
              decoration: BoxDecoration(
                color: routeStatus.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: CustomText(
                text: routeStatus.displayLabel,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s11,
                  color: routeStatus.color,
                ),
              ),
            ),
            SizedBox(height: AppHeight.s12),
          ],
          if (orderStatusShowsDriverContact(routeStatus)) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  disabledBackgroundColor: ColorManager.primary.withValues(
                    alpha: 0.45,
                  ),
                  foregroundColor: ColorManager.defaultWhite,
                  disabledForegroundColor:
                      ColorManager.defaultWhite.withValues(alpha: 0.55),
                  padding: EdgeInsets.symmetric(
                    vertical: AppPadding.p12,
                    horizontal: AppPadding.p14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
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
                      if (order.deliveryMan != null) ...{
                        'deliveryManName': order.deliveryMan!.name,
                        'deliveryManPhone': order.deliveryMan!.phone,
                      },
                    },
                  );
                },
                icon: Icon(
                  routeStatus == OrderStatus.onTheWay
                      ? Icons.my_location_outlined
                      : Icons.local_shipping_outlined,
                  size: 20,
                ),
                label: Text(AppTranslation.orderTrackOrderCta),
              ),
            ),
            SizedBox(height: AppHeight.s16),
          ],
          OrderProductsSection(products: order.products),
          if (dm != null && orderStatusShowsDriverContact(routeStatus)) ...[
            SizedBox(height: AppHeight.s16),
            OrderClientDriverContactCard(
              driverName: dm.name,
              driverPhone: driverPhoneTrimmed.isEmpty
                  ? null
                  : driverPhoneTrimmed,
            ),
            if (showSupportRow) ...[
              SizedBox(height: AppHeight.s10),
              OrderClientSupportPhoneRow(
                supportPhone: supportTrimmed,
                darkBackground: true,
              ),
            ],
          ] else if (dm != null) ...[
            SizedBox(height: AppHeight.s16),
            OrderDeliveryManCard(deliveryMan: dm),
          ],
        ],
      ),
    );
  }
}

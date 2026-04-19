import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/confirmation_dialog.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_delivery_man_card.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_products_section.dart';

class OrderDetailsContent extends StatelessWidget {
  final OrderEntity order;
  final bool isCancelling;

  const OrderDetailsContent({
    super.key,
    required this.order,
    this.isCancelling = false,
  });

  @override
  Widget build(BuildContext context) {
    final routeStatus = OrderStatus.fromString(order.status);
    final restaurant = order.displayRestaurantName;

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
          if (routeStatus.canClientCancelOrder) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade400),
                  padding: EdgeInsets.symmetric(
                    vertical: AppPadding.p12,
                    horizontal: AppPadding.p14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                ),
                onPressed: isCancelling
                    ? null
                    : () {
                        ConfirmationDialog.show(
                          context: context,
                          title: AppTranslation.areYouSureCancelOrder,
                          confirmText: AppTranslation.cancelOrder,
                          confirmColor: Colors.red,
                          onConfirm: () {
                            context.read<OrderDetailsBloc>().add(
                                  const CancelOrderEvent(),
                                );
                          },
                        );
                      },
                child: isCancelling
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade700,
                        ),
                      )
                    : Text(AppTranslation.cancelOrder),
              ),
            ),
            SizedBox(height: AppHeight.s16),
          ],
          if (routeStatus == OrderStatus.onTheWay) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
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
                icon: const Icon(Icons.my_location_outlined, size: 20),
                label: Text(AppTranslation.orderTrackOrderCta),
              ),
            ),
            SizedBox(height: AppHeight.s16),
          ],
          OrderProductsSection(products: order.products),
          if (order.deliveryMan != null) ...[
            SizedBox(height: AppHeight.s16),
            OrderDeliveryManCard(deliveryMan: order.deliveryMan!),
          ],
        ],
      ),
    );
  }
}

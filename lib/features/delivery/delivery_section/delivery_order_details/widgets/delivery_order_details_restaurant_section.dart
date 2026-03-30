import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/delivery_order_meal_prep_countdown.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryOrderDetailsRestaurantSection extends StatelessWidget {
  final OrderEntity order;
  final String restaurantName;
  final VoidCallback? onMealPrepElapsed;

  const DeliveryOrderDetailsRestaurantSection({
    super.key,
    required this.order,
    required this.restaurantName,
    this.onMealPrepElapsed,
  });

  @override
  Widget build(BuildContext context) {
    final addr = order.owner?.address?.trim().isNotEmpty == true
        ? order.owner!.address!.trim()
        : (order.pickupAddress?.trim().isNotEmpty == true
            ? order.pickupAddress!.trim()
            : '');
    final phone = order.owner?.phone?.trim().isNotEmpty == true
        ? order.owner!.phone!.trim()
        : (order.merchantPhone?.trim().isNotEmpty == true
            ? order.merchantPhone!.trim()
            : null);

    final mealMins = order.mealPreparationMinutes ?? order.preparationTime;
    final deliveryMins = order.deliveryTimeMinutes;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAvatarIcon(Icons.restaurant, Colors.orangeAccent),
        SizedBox(width: AppWidth.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: restaurantName,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.primary,
                ),
              ),
              CustomText(
                text: AppTranslation.pickUpPoint,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s11,
                  color: ColorManager.textSecondary,
                ),
              ),
              if (addr.isNotEmpty) ...[
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: addr,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.textSecondary,
                  ),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ],
              if (phone != null) ...[
                SizedBox(height: AppHeight.s8),
                InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_in_talk_outlined,
                        size: AppSize.s16,
                        color: ColorManager.primary,
                      ),
                      SizedBox(width: AppWidth.s8),
                      CustomText(
                        text: phone,
                        textStyle: getSemiBoldStyle(
                          fontSize: AppFontSize.s13,
                          color: ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (deliveryMins != null && deliveryMins > 0) ...[
                SizedBox(height: AppHeight.s8),
                CustomText(
                  text: AppTranslation.orderEstimatedDeliveryMinutes(
                    deliveryMins,
                  ),
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s11,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: AppHeight.s10),
              DeliveryOrderMealPrepCountdown(
                key: ValueKey(
                  '${order.id}_${order.createdAt?.toIso8601String()}_$mealMins',
                ),
                placedAt: order.createdAt,
                preparationMinutes: mealMins,
                onElapsed: onMealPrepElapsed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

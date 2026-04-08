import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class DeliveryOrderDetailsRestaurantSection extends StatelessWidget {
  final OrderEntity order;
  final String restaurantName;

  const DeliveryOrderDetailsRestaurantSection({
    super.key,
    required this.order,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    final addr = order.owner?.address?.trim().isNotEmpty == true
        ? order.owner!.address!.trim()
        : '';
    final restaurantPhone = order.owner?.phone?.trim();

    final mealMins = order.mealPreparationMinutes ?? order.preparationTime;

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
                  color: ColorManager.defaultWhite,
                ),
              ),
              if (addr.isNotEmpty) ...[
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: addr,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.defaultWhite,
                  ),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ],
              if (restaurantPhone != null && restaurantPhone.isNotEmpty) ...[
                SizedBox(height: AppHeight.s8),
                CopyablePhoneRow(phone: restaurantPhone),
              ],
              if (mealMins != null && mealMins > 0) ...[
                SizedBox(height: AppHeight.s10),
                CustomText(
                  text: AppTranslation.preparationTime,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s10,
                    color: ColorManager.defaultWhite,
                  ),
                ),
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: AppTranslation.preparationMinutesLabel(mealMins),
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

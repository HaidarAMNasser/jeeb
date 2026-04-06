import 'package:flutter/material.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class DeliveryOrderMerchant extends StatelessWidget {
  final String restaurantName;
  final String pickupAddressLine;
  final int? preparationMinutes;
  final bool showPreparationTime;

  const DeliveryOrderMerchant({
    super.key,
    required this.restaurantName,
    this.pickupAddressLine = '',
    this.preparationMinutes,
    this.showPreparationTime = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAvatarIcon(Icons.restaurant, Colors.orangeAccent),
        SizedBox(width: AppWidth.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: restaurantName,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.primary,
                ),
              ),
              if (pickupAddressLine.isNotEmpty)
                CustomText(
                  text: pickupAddressLine,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.textSecondary,
                  ),
                  maxLines: 3,
                ),
            ],
          ),
        ),
        if (showPreparationTime) _buildPreparationMinutes(),
      ],
    );
  }

  Widget _buildPreparationMinutes() {
    final mins = preparationMinutes;
    if (mins == null || mins <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          text: AppTranslation.preparationTime,
          textStyle: getRegularStyle(
            fontSize: AppFontSize.s10,
            color: ColorManager.textSecondary,
          ),
        ),
        SizedBox(height: AppHeight.s4),
        CustomText(
          text: AppTranslation.preparationMinutesLabel(mins),
          textStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s13,
            color: ColorManager.primary,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class DeliveryOrderMerchant extends StatelessWidget {
  final String restaurantName;
  final Duration preparationDuration;

  const DeliveryOrderMerchant({
    super.key,
    required this.restaurantName,
    required this.preparationDuration,
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
              CustomText(
                text: AppTranslation.pickUpPoint,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildPreparationTimer(),
      ],
    );
  }

  Widget _buildPreparationTimer() {
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
        SlideCountdown(
          duration: preparationDuration,
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSize.s8),
          ),
          style: getSemiBoldStyle(
            fontSize: AppFontSize.s12,
            color: ColorManager.primary,
          ),
          separatorStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s12,
            color: ColorManager.primary,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p8,
            vertical: AppPadding.p2,
          ),
        ),
      ],
    );
  }
}

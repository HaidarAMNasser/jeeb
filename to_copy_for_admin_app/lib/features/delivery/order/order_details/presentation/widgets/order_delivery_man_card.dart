import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class OrderDeliveryManCard extends StatelessWidget {
  final DeliveryManEntity deliveryMan;

  const OrderDeliveryManCard({super.key, required this.deliveryMan});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.defaultWhite,
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: AppTranslation.deliveryMan,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.productNameColor,
              ),
            ),
            SizedBox(height: AppHeight.s12),
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: ColorManager.primary,
                  size: AppSize.s20,
                ),
                SizedBox(width: AppWidth.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: deliveryMan.name,
                        textStyle: getBoldStyle(
                          fontSize: AppFontSize.s14,
                          color: ColorManager.productNameColor,
                        ),
                      ),
                      SizedBox(height: AppHeight.s4),
                      CustomText(
                        text: deliveryMan.email,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s12,
                          color: ColorManager.descriptionColor,
                        ),
                      ),
                      if (deliveryMan.phone.isNotEmpty) ...[
                        SizedBox(height: AppHeight.s4),
                        CustomText(
                          text: deliveryMan.phone,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s12,
                            color: ColorManager.descriptionColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

class OrderLocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;

  const OrderLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.defaultWhite,
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: ColorManager.primary,
                  size: AppSize.s20,
                ),
                SizedBox(width: AppWidth.s12),
                CustomText(
                  text: AppTranslation.location,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: ColorManager.productNameColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppHeight.s8),
            CustomText(
              text: '${AppTranslation.latitude}: $latitude',
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.descriptionColor,
              ),
            ),
            SizedBox(height: AppHeight.s4),
            CustomText(
              text: '${AppTranslation.longitude}: $longitude',
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.descriptionColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


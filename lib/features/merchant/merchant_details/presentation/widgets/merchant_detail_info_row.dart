import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Icon + label + value (used on merchant details screen).
class MerchantDetailInfoRow extends StatelessWidget {
  const MerchantDetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppSize.s20,
          color: ColorManager.descriptionColor,
        ),
        SizedBox(width: AppWidth.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: label,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.descriptionColor,
                ),
              ),
              SizedBox(height: AppHeight.s4),
              CustomText(
                text: value,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.productNameColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

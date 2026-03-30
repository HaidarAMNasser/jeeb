import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';

class DeliveryOrderHeader extends StatelessWidget {
  final String recipientName;
  final String recipientAddress;
  final int totalPrice;

  const DeliveryOrderHeader({
    super.key,
    required this.recipientName,
    required this.recipientAddress,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        buildAvatarIcon(Icons.person, ColorManager.primary),
        SizedBox(width: AppWidth.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: recipientName,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s18,
                  color: ColorManager.titlesColor,
                ),
              ),
              if (recipientAddress.isNotEmpty)
                CustomText(
                  text: recipientAddress,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        buildPriceTag(totalPrice),
      ],
    );
  }
}

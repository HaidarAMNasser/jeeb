import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class DeliveryOrderPriceSection extends StatelessWidget {
  final int deliveryFee;
  final int deliveryEarning;

  const DeliveryOrderPriceSection({
    super.key,
    required this.deliveryFee,
    required this.deliveryEarning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPriceRow(
          icon: Icons.delivery_dining_outlined,
          label: AppTranslation.deliveryPrice,
          value: deliveryFee,
          color: ColorManager.titlesColor,
        ),
        SizedBox(height: AppHeight.s8),
        _buildPriceRow(
          icon: Icons.account_balance_wallet_outlined,
          label: AppTranslation.deliveryEarning,
          value: deliveryEarning,
          color: ColorManager.primary,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSize.s12),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSize.s18, color: color),
              SizedBox(width: AppWidth.s8),
              CustomText(
                text: label,
                textStyle: (isBold ? getSemiBoldStyle : getRegularStyle)(
                  fontSize: AppFontSize.s14,
                  color: color,
                ),
              ),
            ],
          ),
          CustomText(
            text: '\$${(value / 100).toStringAsFixed(2)}',
            textStyle: (isBold ? getBoldStyle : getSemiBoldStyle)(
              fontSize: AppFontSize.s16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

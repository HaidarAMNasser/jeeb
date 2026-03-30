import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Order totals from API: `itemsTotal`, `offersTotal`, `deliveryFee`, `totalAmount`.
class DeliveryOrderPriceSection extends StatelessWidget {
  final int itemsTotal;
  final int offersTotal;
  final int deliveryFee;
  final int totalAmount;
  /// Details screen: delivery fee → offers → items → grand total.
  final bool detailsTotalsOrder;

  const DeliveryOrderPriceSection({
    super.key,
    required this.itemsTotal,
    required this.offersTotal,
    required this.deliveryFee,
    required this.totalAmount,
    this.detailsTotalsOrder = false,
  });

  @override
  Widget build(BuildContext context) {
    final delivery = _buildPriceRow(
      icon: Icons.delivery_dining_outlined,
      label: AppTranslation.deliveryPrice,
      value: deliveryFee,
      color: ColorManager.titlesColor,
    );
    final offers = _buildPriceRow(
      icon: Icons.local_offer_outlined,
      label: AppTranslation.orderOffersTotal,
      value: offersTotal,
      color: ColorManager.titlesColor,
    );
    final items = _buildPriceRow(
      icon: Icons.shopping_bag_outlined,
      label: AppTranslation.orderItemsTotal,
      value: itemsTotal,
      color: ColorManager.titlesColor,
    );
    final total = _buildPriceRow(
      icon: Icons.payments_outlined,
      label: AppTranslation.total,
      value: totalAmount,
      color: ColorManager.primary,
      isBold: true,
    );

    final mid = detailsTotalsOrder
        ? [delivery, offers, items]
        : [items, offers, delivery];

    return Column(
      children: [
        mid[0],
        SizedBox(height: AppHeight.s8),
        mid[1],
        SizedBox(height: AppHeight.s8),
        mid[2],
        SizedBox(height: AppHeight.s8),
        total,
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

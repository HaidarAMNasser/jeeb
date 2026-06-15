import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_money.dart';

/// Order totals from API: `itemsTotal`, `offersTotal`, `deliveryFee`, `totalAmount`.
class DeliveryOrderPriceSection extends StatelessWidget {
  final int itemsTotal;
  final int offersTotal;
  final int deliveryFee;
  final int totalAmount;

  /// Details screen: delivery fee → offers → items → grand total.
  final bool detailsTotalsOrder;

  final bool showGrandTotal;

  /// Tighter rows for list cards.
  final bool compactRows;

  /// Prominent grand total bar (cards only).
  final bool capstoneGrandTotal;

  const DeliveryOrderPriceSection({
    super.key,
    required this.itemsTotal,
    required this.offersTotal,
    required this.deliveryFee,
    required this.totalAmount,
    this.detailsTotalsOrder = false,
    this.showGrandTotal = true,
    this.compactRows = false,
    this.capstoneGrandTotal = false,
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

    final mid = detailsTotalsOrder
        ? [delivery, offers, items]
        : [items, offers, delivery];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        mid[0],
        SizedBox(height: compactRows ? AppHeight.s5 : AppHeight.s8),
        mid[1],
        SizedBox(height: compactRows ? AppHeight.s5 : AppHeight.s8),
        mid[2],
        if (showGrandTotal) ...[
          SizedBox(height: compactRows ? AppHeight.s12 : AppHeight.s8),
          capstoneGrandTotal
              ? _buildCapstoneTotal()
              : _buildStandardTotalRow(),
        ],
      ],
    );
  }

  Widget _buildStandardTotalRow() {
    return _buildPriceRow(
      icon: Icons.payments_outlined,
      label: AppTranslation.total,
      value: totalAmount,
      color: ColorManager.primary,
      isBold: true,
    );
  }

  Widget _buildCapstoneTotal() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p14,
        vertical: AppPadding.p14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary.withOpacity(0.14),
            ColorManager.titlesColor.withOpacity(0.06),
          ],
        ),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            AppTranslation.total.toUpperCase(),
            style: TextStyle(
              fontSize: AppFontSize.s10,
              letterSpacing: 1.15,
              fontWeight: FontWeight.w600,
              color: ColorManager.textSecondary.withOpacity(0.95),
            ),
          ),
          OrderMoneyText(
            minor: totalAmount,
            style: OrderMoneyStyle.capstone,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    bool isBold = false,
  }) {
    final pad = compactRows ? AppPadding.p10 : AppPadding.p12;
    final iconSize = compactRows ? AppSize.s16 : AppSize.s18;
    final labelSize = compactRows ? AppFontSize.s12 : AppFontSize.s14;
    final valueSize = compactRows ? AppFontSize.s13 : AppFontSize.s16;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: color.withOpacity(compactRows ? 0.04 : 0.05),
        borderRadius: BorderRadius.circular(
          compactRows ? AppSize.s10 : AppSize.s12,
        ),
        border: Border.all(
          color: color.withOpacity(0.09),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: iconSize, color: color.withOpacity(0.9)),
              SizedBox(width: AppWidth.s8),
              CustomText(
                text: label,
                textStyle: (isBold ? getSemiBoldStyle : getRegularStyle)(
                  fontSize: labelSize,
                  color: color,
                ),
              ),
            ],
          ),
          if (isBold)
            CustomText(
              text: 'SYP ${(value / 100).toStringAsFixed(2)}',
              textStyle: getBoldStyle(
                fontSize: valueSize,
                color: color,
              ),
            )
          else
            OrderMoneyText(
              minor: value,
              style: OrderMoneyStyle.inline,
            ),
        ],
      ),
    );
  }
}

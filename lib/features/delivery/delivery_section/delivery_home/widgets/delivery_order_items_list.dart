import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_money.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class DeliveryOrderItemsList extends StatelessWidget {
  final List<ProductEntity> products;
  final List<OrderLineProductEntity> lineItems;

  const DeliveryOrderItemsList({
    super.key,
    required this.products,
    this.lineItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final useLines = lineItems.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(
                color: ColorManager.textSecondary,
                thickness: 0.5,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.p12),
              child: CustomText(
                text: AppTranslation.orderItems,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.textSecondary,
                ),
              ),
            ),
            const Expanded(
              child: Divider(
                color: ColorManager.textSecondary,
                thickness: 0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: AppHeight.s16),
        if (useLines)
          ...lineItems.map(_buildLineItemRow)
        else
          ...products.map(_buildProductFallbackRow),
      ],
    );
  }

  Widget _buildLineItemRow(OrderLineProductEntity line) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.p10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppPadding.p4),
            child: Icon(
              Icons.circle,
              size: 6,
              color: ColorManager.primary.withOpacity(0.55),
            ),
          ),
          SizedBox(width: AppWidth.s8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomText(
                    text: line.productName,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.titlesColor.withOpacity(0.92),
                    ),
                    maxLines: 2,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.p10),
                  child: CustomText(
                    text: '×${line.quantity}',
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s12,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ),
                OrderMoneyText(minor: line.lineTotalMinor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductFallbackRow(ProductEntity p) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.p10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppPadding.p4),
            child: Icon(
              Icons.circle,
              size: 6,
              color: ColorManager.primary.withOpacity(0.55),
            ),
          ),
          SizedBox(width: AppWidth.s8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomText(
                    text: p.name,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.titlesColor.withOpacity(0.92),
                    ),
                    maxLines: 2,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.p10),
                  child: CustomText(
                    text: '×1',
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s12,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ),
                OrderMoneyText(minor: p.displayPrice),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

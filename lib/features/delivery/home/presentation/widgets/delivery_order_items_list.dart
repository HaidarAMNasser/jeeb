import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class DeliveryOrderItemsList extends StatelessWidget {
  final List<ProductEntity> products;

  const DeliveryOrderItemsList({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        ...products.map((p) => _buildItemRow(p.name, p.displayPrice)),
      ],
    );
  }

  Widget _buildItemRow(String name, int price) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: ColorManager.primary.withOpacity(0.5),
                ),
                SizedBox(width: AppWidth.s8),
                Expanded(
                  child: CustomText(
                    text: name,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.titlesColor.withOpacity(0.9),
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          CustomText(
            text: '\$${(price / 100).toStringAsFixed(2)}',
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.titlesColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

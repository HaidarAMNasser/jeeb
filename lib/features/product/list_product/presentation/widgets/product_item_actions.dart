import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

class ProductItemActions extends StatelessWidget {
  final String productId;
  final bool enableSmallDesign;
  final int price;
  final int? displayPrice;
  final double? commissionRate;
  final bool showConfirmProduct;
  final int? stockQuantity;
  final bool? hasStock;

  const ProductItemActions({
    super.key,
    required this.productId,
    this.enableSmallDesign = false,
    required this.price,
    this.displayPrice,
    this.commissionRate,
    this.showConfirmProduct = false,
    this.stockQuantity,
    this.hasStock,
  });

  String get _priceText {
    final base = (price / 100).toStringAsFixed(2);
    final total = ((displayPrice ?? price) / 100).toStringAsFixed(2);
    if (commissionRate != null &&
        commissionRate! > 0 &&
        displayPrice != null &&
        displayPrice != price) {
      return '\$$base + $commissionRate% = \$$total';
    }
    return '\$$total';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (!enableSmallDesign)
              Expanded(
                child: CustomText(
                  text: _priceText,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s20,
                    color: ColorManager.primary,
                  ),
                ),
              ),
          ],
        ),
        if (stockQuantity != null && hasStock == true) ...[
          SizedBox(height: AppHeight.s8),
          CustomText(
            text: '${AppTranslation.productQuantity}: $stockQuantity',
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.descriptionColor,
            ),
          ),
        ],
      ],
    );
  }
}
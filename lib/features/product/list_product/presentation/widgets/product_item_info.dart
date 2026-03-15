import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class ProductItemInfo extends StatelessWidget {
  final ProductEntity product;
  final bool enableSmallDesign;
  const ProductItemInfo({
    super.key,
    required this.product,
    this.enableSmallDesign = false,
  });

  String get _priceText {
    final display = (product.displayPrice / 100).toStringAsFixed(2);
    if (product.commissionRate != null &&
        product.commissionRate! > 0 &&
        product.finalPrice != null &&
        product.finalPrice != product.price) {
      return ' \$$display';
    }
    return '\$$display';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        enableSmallDesign
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      text: product.name,
                      textStyle: getBoldStyle(
                        fontSize: AppFontSize.s18,
                        color: ColorManager.productNameColor,
                      ),
                      maxLines: 2,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CustomText(
                    text: _priceText,
                    textStyle: getBoldStyle(
                      fontSize: AppFontSize.s20,
                      color: ColorManager.primary,
                    ),
                  ),
                ],
              )
            : CustomText(
                text: product.name,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s18,
                  color: ColorManager.productNameColor,
                ),
                maxLines: 2,
                textOverflow: TextOverflow.ellipsis,
              ),
        if (product.description != null) ...[
          SizedBox(height: AppHeight.s4),
          CustomText(
            text: product.description!,
            textStyle: getRegularStyle(color: ColorManager.descriptionColor),
            maxLines: 2,
            textOverflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

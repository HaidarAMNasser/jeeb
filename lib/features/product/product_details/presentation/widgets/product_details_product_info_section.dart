import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/product_details/presentation/widgets/product_details_availability_row.dart';
import 'package:jeeb_app/features/product/product_details/presentation/widgets/product_details_image_gallery.dart';

class ProductDetailsProductInfoSection extends StatelessWidget {
  final ProductEntity product;

  const ProductDetailsProductInfoSection({super.key, required this.product});

  static String formatPrice(int cents) => (cents / 100).toStringAsFixed(2);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductDetailsImageGallery(images: product.images),
        Padding(
          padding: EdgeInsets.all(AppPadding.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _nameAndCategory(),
              SizedBox(height: AppHeight.s12),
              CustomText(
                text:
                    ' \$${formatPrice(product.finalPrice!)}',
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s22,
                  color: ColorManager.primary,
                ),
              ),
              SizedBox(height: AppHeight.s16),
              if (product.personCount != null && product.personCount! > 0) ...[
                _personCount(),
                SizedBox(height: AppHeight.s12),
              ],
              if (product.shortDescription != null &&
                  product.shortDescription!.isNotEmpty) ...[
                _sectionTitle(AppTranslation.summary),
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: product.shortDescription!,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.textSecondary,
                  ),
                ),
                SizedBox(height: AppHeight.s16),
              ],
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                _sectionTitle(AppTranslation.productDescription),
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: product.description!,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.textSecondary,
                  ),
                ),
                SizedBox(height: AppHeight.s16),
              ],
              ProductDetailsAvailabilityRow(
                hasStock: product.hasStock,
                stockQuantity: product.stockQuantity,
                isAvailable: product.isAvailable,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return CustomText(
      text: title,
      textStyle: getSemiBoldStyle(
        fontSize: AppFontSize.s16,
        color: ColorManager.defaultWhite,
      ),
    );
  }

  Widget _nameAndCategory() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CustomText(
            text: product.name,
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s24,
              color: ColorManager.defaultWhite,
            ),
          ),
        ),
        if (product.categoryName != null &&
            product.categoryName!.isNotEmpty) ...[
          SizedBox(width: AppPadding.p12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.p12,
              vertical: AppPadding.p6,
            ),
            decoration: BoxDecoration(
              color: ColorManager.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomText(
              text: product.categoryName!,
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s12,
                color: ColorManager.defaultWhite,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _personCount() {
    return Row(
      children: [
        Icon(Icons.person_outline, size: 20, color: ColorManager.primary),
        SizedBox(width: AppPadding.p8),
        CustomText(
          text: AppTranslation.servesCountN(product.personCount!),
          textStyle: getRegularStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.textColor,
          ),
        ),
      ],
    );
  }
}

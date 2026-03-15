import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';


class ProductDetailsContent extends StatelessWidget {
  final ProductEntity product;
  final bool isAdmin;
  final VoidCallback onEdit;

  const ProductDetailsContent({
    super.key,
    required this.product,
    required this.isAdmin,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final priceStr = (product.price / 100).toStringAsFixed(2);
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (product.images.isNotEmpty) _ProductImage(url: product.images.first.url),
          SizedBox(height: AppHeight.s16),
          CustomText(
            text: product.name,
            textStyle: getBoldStyle(
              fontSize: 24,
              color: ColorManager.defaultWhite,
            ),
          ),
          SizedBox(height: AppHeight.s8),
          CustomText(
            text: priceStr,
            textStyle: getBoldStyle(
              fontSize: 20,
              color: ColorManager.primary,
            ),
          ),
          SizedBox(height: AppHeight.s16),
          if (product.description != null)
            CustomText(
              text: product.description!,
              textStyle: getRegularStyle(color: ColorManager.textColor),
            ),
          SizedBox(height: AppHeight.s24),
          if (!isAdmin)
            CustomButton(
              text: AppTranslation.editProduct,
              onPressed: onEdit,
              color: ColorManager.primary,
            ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String url;

  const _ProductImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

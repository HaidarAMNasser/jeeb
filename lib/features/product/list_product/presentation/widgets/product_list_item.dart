import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_input_dialog.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class ProductListItem extends StatelessWidget {
  final ProductEntity product;

  /// When true, shows the "Confirm product" button (admin only).
  final bool showConfirmProduct;

  const ProductListItem({
    super.key,
    required this.product,
    this.showConfirmProduct = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppRouter.navigateTo(
          context,
          Routes.productDetails,
          arguments: {'productId': product.id},
        );
      },
      child: Card(
        color: ColorManager.defaultWhite,
        margin: EdgeInsets.only(bottom: AppMargin.m16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppPadding.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      if (product.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.r100),
                          ),
                          child: Container(
                            width: AppWidth.s50,
                            height: AppHeight.s50,
                            color: ColorManager.background,
                            child: Image.network(
                              product.images.first.url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: ColorManager.background,
                                  child: Icon(
                                    Icons.image,
                                    color: ColorManager.defaultWhite
                                        .withOpacity(0.3),
                                    size: AppSize.s28,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      SizedBox(width: AppWidth.s8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppPadding.p12,
                          vertical: AppPadding.p4,
                        ),
                        decoration: BoxDecoration(
                          color: ColorManager.categoryBadgeBackground,
                          borderRadius: BorderRadius.circular(AppRadius.r20),
                        ),
                        child: CustomText(
                          text: product.categoryName ?? '',
                          textStyle: getSemiBoldStyle(
                            fontSize: AppFontSize.s12,
                            color: ColorManager.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (product.rating != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppPadding.p8,
                        vertical: AppPadding.p4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.ratingBackgroundColor,
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: ColorManager.primary,
                            size: AppSize.s16,
                          ),
                          SizedBox(width: AppWidth.s4),
                          CustomText(
                            text: product.rating!.toStringAsFixed(1),
                            textStyle: getSemiBoldStyle(
                              fontSize: AppFontSize.s12,
                              color: ColorManager.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppHeight.s8),
              // Product Name
              CustomText(
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
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.descriptionColor,
                  ),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: AppHeight.s12),
              // Price and Rating Row
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text:
                          '\$${(product.price / 100).toStringAsFixed(2)}', // convert smallest unit
                      textStyle: getBoldStyle(
                        fontSize: AppFontSize.s20,
                        color: ColorManager.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (product.stockQuantity != null &&
                  product.hasStock == true) ...[
                SizedBox(height: AppHeight.s8),
                CustomText(
                  text:
                      '${AppTranslation.productQuantity}: ${product.stockQuantity}',
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.descriptionColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

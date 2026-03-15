import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';

/// Maximum number of products to show in the merchant details preview.
const int _kMerchantProductsPreviewLimit = 3;

class MerchantProductsSection extends StatelessWidget {
  final String merchantId;

  const MerchantProductsSection({super.key, required this.merchantId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListProductBloc, ListProductState>(
      builder: (context, state) {
        if (state is ListProductLoading || state is ListProductInitial) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: AppTranslation.products,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s20,
                  color: ColorManager.titlesColor,
                ),
              ),
              SizedBox(height: AppHeight.s16),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppPadding.p24),
                  child: CustomCircleIndicator(),
                ),
              ),
            ],
          );
        }

        if (state is ListProductError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: AppTranslation.products,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s20,
                  color: ColorManager.titlesColor,
                ),
              ),
              SizedBox(height: AppHeight.s16),
              CustomText(
                text: state.message,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.error,
                ),
              ),
            ],
          );
        }

        final productList = state is ListProductLoaded
            ? state.products
            : (state is ListProductLoadingMore)
            ? state.products
            : <ProductEntity>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  text: AppTranslation.products,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s20,
                    color: ColorManager.titlesColor,
                  ),
                ),
                if (productList.isNotEmpty)
                  InkWell(
                    onTap: () {
                      context.pushNamed(
                        Routes.products,
                        arguments: {'merchantId': merchantId},
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppPadding.p8,
                        vertical: AppPadding.p4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: AppTranslation.showAll,
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s14,
                              color: ColorManager.defaultWhite,
                            ),
                          ),
                          SizedBox(width: AppWidth.s4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: AppSize.s20,
                            color: ColorManager.defaultWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppHeight.s16),
            if (productList.isEmpty)
              CustomText(
                text: AppTranslation.noProductsFound,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.descriptionColor,
                ),
              )
            else
              ...productList
                  .take(_kMerchantProductsPreviewLimit)
                  .map((p) => ProductListItem(product: p)),
          ],
        );
      },
    );
  }
}

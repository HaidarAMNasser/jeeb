import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';

class OrderProductsSection extends StatelessWidget {
  final List<ProductEntity> products;

  const OrderProductsSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: '${AppTranslation.products} (${products.length})',
          textStyle: getBoldStyle(
            fontSize: AppFontSize.s18,
            color: ColorManager.defaultWhite,
          ),
        ),
        SizedBox(height: AppHeight.s12),
        ...products.map((product) => Padding(
              padding: EdgeInsets.only(bottom: AppPadding.p12),
              child: ProductListItem(product: product),
            )),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/product_details/presentation/widgets/product_details_merchant_section.dart';
import 'package:jeeb_app/features/product/product_details/presentation/widgets/product_details_product_info_section.dart';

/// Composes product details: product info section + merchant section. Max ~140 lines per file.
class ProductDetailsContent extends StatelessWidget {
  final ProductEntity product;

  const ProductDetailsContent({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductDetailsProductInfoSection(product: product),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
            child: ProductDetailsMerchantSection(
              merchantName: product.merchantName,
              merchantAddress: product.merchantAddress,
              merchantPhone: product.merchantPhone,
            ),
          ),
          SizedBox(height: AppHeight.s24),
        ],
      ),
    );
  }
}

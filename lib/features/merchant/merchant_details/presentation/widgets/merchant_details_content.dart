import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/merchant/merchant_details/presentation/widgets/merchant_details_info_card.dart';
import 'package:jeeb_app/features/merchant/merchant_details/presentation/widgets/merchant_offers_section.dart';
import 'package:jeeb_app/features/merchant/merchant_details/presentation/widgets/merchant_products_section.dart';

class MerchantDetailsContent extends StatelessWidget {
  final MerchantEntity merchant;
  final String merchantId;
  final ScrollController? scrollController;

  const MerchantDetailsContent({
    super.key,
    required this.merchant,
    required this.merchantId,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MerchantDetailsInfoCard(merchant: merchant),
            SizedBox(height: AppHeight.s24),
            MerchantProductsSection(merchantId: merchantId),
            SizedBox(height: AppHeight.s24),
            MerchantOffersSection(merchantId: merchantId),
            SizedBox(height: AppHeight.s24),
          ],
        ),
      ),
    );
  }
}

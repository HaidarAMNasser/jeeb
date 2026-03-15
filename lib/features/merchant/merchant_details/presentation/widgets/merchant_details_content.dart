import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
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
    return Padding(
      padding: EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Merchant Info Card
          Card(
            color: ColorManager.defaultWhite,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.r16),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppPadding.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (merchant.image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.r100),
                          ),
                          child: Container(
                            width: AppWidth.s100,
                            height: AppHeight.s100,
                            color: ColorManager.background,
                            child: Image.network(
                              merchant.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: ColorManager.background,
                                  child: Icon(
                                    Icons.store,
                                    color: ColorManager.primary,
                                    size: AppSize.s40,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          width: AppWidth.s100,
                          height: AppHeight.s100,
                          decoration: BoxDecoration(
                            color: ColorManager.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.store,
                            color: ColorManager.primary,
                            size: AppSize.s40,
                          ),
                        ),
                      SizedBox(width: AppWidth.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: merchant.name,
                              textStyle: getBoldStyle(
                                fontSize: AppFontSize.s20,
                                color: ColorManager.productNameColor,
                              ),
                            ),
                            SizedBox(height: AppHeight.s4),
                            CustomText(
                              text: merchant.email,
                              textStyle: getRegularStyle(
                                fontSize: AppFontSize.s14,
                                color: ColorManager.descriptionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppHeight.s16),
                  if (merchant.phoneNumber != null) ...[
                    _buildInfoRow(
                      Icons.phone,
                      AppTranslation.phone,
                      merchant.phoneNumber!,
                    ),
                    SizedBox(height: AppHeight.s12),
                  ],
                  if (merchant.cityName != null ||
                      merchant.countryName != null) ...[
                    _buildInfoRow(
                      Icons.location_on,
                      AppTranslation.location,
                      '${merchant.cityName ?? ''}${merchant.cityName != null && merchant.countryName != null ? ', ' : ''}${merchant.countryName ?? ''}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: AppHeight.s24),
          // Products Section (limit 3 + Show all)
          MerchantProductsSection(merchantId: merchantId),
          SizedBox(height: AppHeight.s24),
          // Offers Section (limit 3 + Show all)
          MerchantOffersSection(merchantId: merchantId),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSize.s20,
          color: ColorManager.descriptionColor,
        ),
        SizedBox(width: AppWidth.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: label,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.descriptionColor,
                ),
              ),
              SizedBox(height: AppHeight.s4),
              CustomText(
                text: value,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.productNameColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/merchant_default_cover_image.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/merchant/merchant_details/presentation/widgets/merchant_detail_info_row.dart';

/// White card: avatar + restaurant name, phone, location (one row: avatar | text column).
class MerchantDetailsInfoCard extends StatelessWidget {
  const MerchantDetailsInfoCard({super.key, required this.merchant});

  final MerchantEntity merchant;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.defaultWhite,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.r100)),
              child: SizedBox(
                width: AppWidth.s100,
                height: AppHeight.s100,
                child: merchant.image != null && merchant.image!.isNotEmpty
                    ? Image.network(
                        merchant.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            MerchantDefaultCoverImage(height: AppHeight.s100),
                      )
                    : MerchantDefaultCoverImage(height: AppHeight.s100),
              ),
            ),
            SizedBox(width: AppWidth.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: merchant.restaurantName,
                    textStyle: getBoldStyle(
                      fontSize: AppFontSize.s18,
                      color: ColorManager.productNameColor,
                    ),
                    maxLines: 3,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  if (merchant.shouldShowPhone) ...[
                    SizedBox(height: AppHeight.s12),
                    MerchantDetailInfoRow(
                      icon: Icons.phone,
                      label: AppTranslation.phone,
                      value: merchant.phoneNumber!,
                    ),
                  ],
                  if (merchant.cityName != null || merchant.countryName != null) ...[
                    SizedBox(height: AppHeight.s12),
                    MerchantDetailInfoRow(
                      icon: Icons.location_on,
                      label: AppTranslation.location,
                      value:
                          '${merchant.cityName ?? ''}${merchant.cityName != null && merchant.countryName != null ? ', ' : ''}${merchant.countryName ?? ''}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

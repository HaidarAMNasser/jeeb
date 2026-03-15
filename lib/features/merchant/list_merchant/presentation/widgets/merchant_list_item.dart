import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';

class MerchantListItem extends StatelessWidget {
  final MerchantEntity merchant;

  const MerchantListItem({super.key, required this.merchant});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppRouter.navigateTo(
          context,
          Routes.merchantDetails,
          arguments: {'merchantId': merchant.id},
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (merchant.image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.r100),
                          ),
                          child: Container(
                            width: AppWidth.s50,
                            height: AppHeight.s50,
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
                                    size: AppSize.s28,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      else
                        Container(
                          width: AppWidth.s50,
                          height: AppHeight.s50,
                          decoration: BoxDecoration(
                            color: ColorManager.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.store,
                            color: ColorManager.primary,
                            size: AppSize.s28,
                          ),
                        ),
                      SizedBox(width: AppWidth.s12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: merchant.name,
                            textStyle: getBoldStyle(
                              fontSize: AppFontSize.s18,
                              color: ColorManager.productNameColor,
                            ),
                            maxLines: 2,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppHeight.s4),
                          CustomText(
                            text: merchant.email,
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s12,
                              color: ColorManager.descriptionColor,
                            ),
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (merchant.cityName != null || merchant.countryName != null) ...[
                SizedBox(height: AppHeight.s12),
                Row(
                  children: [
                    if (merchant.cityName != null) ...[
                      Icon(
                        Icons.location_city,
                        size: AppSize.s16,
                        color: ColorManager.descriptionColor,
                      ),
                      SizedBox(width: AppWidth.s4),
                      CustomText(
                        text: merchant.cityName!,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s12,
                          color: ColorManager.descriptionColor,
                        ),
                      ),
                    ],
                    if (merchant.countryName != null) ...[
                      if (merchant.cityName != null) ...[
                        SizedBox(width: AppWidth.s8),
                        CustomText(
                          text: '•',
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s12,
                            color: ColorManager.descriptionColor,
                          ),
                        ),
                        SizedBox(width: AppWidth.s8),
                      ],
                      CustomText(
                        text: merchant.countryName!,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s12,
                          color: ColorManager.descriptionColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (merchant.phoneNumber != null) ...[
                SizedBox(height: AppHeight.s8),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: AppSize.s16,
                      color: ColorManager.descriptionColor,
                    ),
                    SizedBox(width: AppWidth.s4),
                    CustomText(
                      text: merchant.phoneNumber!,
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s12,
                        color: ColorManager.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


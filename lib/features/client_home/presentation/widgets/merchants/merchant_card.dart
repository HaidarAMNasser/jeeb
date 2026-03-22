import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';

class MerchantCard extends StatelessWidget {
  final MerchantEntity merchant;

  const MerchantCard({super.key, required this.merchant});

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
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.r16),
                      ),
                      child:
                          merchant.image != null && merchant.image!.isNotEmpty
                          ? Image.network(
                              merchant.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  if (merchant.isOnline == true)
                    Positioned(
                      top: AppPadding.p8,
                      right: AppPadding.p8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorManager.defaultWhite,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.p8,
                  vertical: AppPadding.p2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _scrollableText(
                      text: merchant.name,
                      textStyle: getSemiBoldStyle(
                        fontSize: AppFontSize.s14,
                        color: ColorManager.productNameColor,
                      ),
                    ),
                    if (merchant.cityName != null &&
                        merchant.cityName!.isNotEmpty) ...[
                      SizedBox(height: AppHeight.s2_5),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppPadding.p6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.r8),
                        ),
                        child: CustomText(
                          text: merchant.cityName!,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s8,
                            color: ColorManager.primary,
                          ),
                          maxLines: 1,
                          textOverflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: ColorManager.background,
      child: Icon(
        Icons.store,
        color: ColorManager.primary.withOpacity(0.5),
        size: 40,
      ),
    );
  }

  Widget _scrollableText({required String text, required TextStyle textStyle}) {
    return SizedBox(
      width: double.infinity,
      height: AppHeight.s18,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CustomText(text: text, textStyle: textStyle, maxLines: 1),
      ),
    );
  }
}

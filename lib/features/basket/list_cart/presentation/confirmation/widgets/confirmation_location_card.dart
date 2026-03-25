import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/resolved_address_caption.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Same address formatting as registration ([ResolvedAddressCaption] + geocoding),
/// not a single `country city street` line (order and sanitization differ).
class ConfirmationLocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isResolvingAddress;
  final String? country;
  final String? city;
  final String? street;

  const ConfirmationLocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isResolvingAddress,
    this.country,
    this.city,
    this.street,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: AppTranslation.selectedLocation,
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s13,
              color: ColorManager.productNameColor,
            ),
          ),
          if (isResolvingAddress) ...[
            SizedBox(height: AppHeight.s8),
            Row(
              children: [
                SizedBox(
                  width: AppSize.s14,
                  height: AppSize.s14,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppWidth.s8),
                Expanded(
                  child: CustomText(
                    text: AppTranslation.location,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s12,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: AppHeight.s5),
            ResolvedAddressCaption(
              country: country,
              city: city,
              street: street,
              fallbackLine: AppTranslation.locationSetFormat,
              latitude: latitude,
              longitude: longitude,
              compactSingleLine: true,
            ),
          ],
        ],
      ),
    );
  }
}

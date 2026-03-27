import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/resolved_address_caption.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Picked map location + optional re-pick.
class BasketConfirmationMapSection extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isResolvingAddress;
  final String? country;
  final String? city;
  final String? streetPreview;
  final VoidCallback? onUpdateLocation;

  const BasketConfirmationMapSection({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isResolvingAddress,
    this.country,
    this.city,
    this.streetPreview,
    this.onUpdateLocation,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  text: AppTranslation.selectedLocation,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s13,
                    color: ColorManager.productNameColor,
                  ),
                ),
              ),
              if (onUpdateLocation != null)
                TextButton(
                  onPressed: isResolvingAddress ? null : onUpdateLocation,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: ColorManager.primary,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(AppPadding.p8),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Icon(Icons.edit, size: AppSize.s16),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppHeight.s5),
          if (isResolvingAddress)
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
            )
          else ...[
            SizedBox(height: AppHeight.s5),
            ResolvedAddressCaption(
              country: country,
              city: city,
              street: streetPreview,
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

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/resolved_address_caption.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Registration "Use my location" row (UI only; geocoding lives in [AddressGeocoding]).
class LocationSourceSelector extends StatelessWidget {
  final String title;
  final String useMyLocationHint;
  final String locationSetFallbackHint;
  final double? latitude;
  final double? longitude;
  final String? displayCountry;
  final String? displayCity;
  final String? displayStreet;
  final bool isRequired;
  final VoidCallback onPickLocation;
  final VoidCallback? onClearLocation;
  final bool isLoading;

  const LocationSourceSelector({
    super.key,
    required this.title,
    required this.useMyLocationHint,
    required this.locationSetFallbackHint,
    this.latitude,
    this.longitude,
    this.displayCountry,
    this.displayCity,
    this.displayStreet,
    this.isRequired = false,
    required this.onPickLocation,
    this.onClearLocation,
    this.isLoading = false,
  });

  bool get hasLocation => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CustomText(
              text: title,
              textStyle: getSemiBoldStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.defaultWhite,
              ),
            ),
            if (isRequired)
              CustomText(
                text: ' *',
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.warning,
                ),
              ),
          ],
        ),
        SizedBox(height: AppHeight.s8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r18),
            onTap: isLoading || hasLocation ? null : onPickLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(minHeight: AppHeight.s48),
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p12,
                vertical: AppPadding.p8,
              ),
              decoration: BoxDecoration(
                color: ColorManager.defaultWhite,
                borderRadius: BorderRadius.circular(AppRadius.r18),
                border: Border.all(color: ColorManager.borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    hasLocation ? Icons.location_on : Icons.my_location,
                    size: 22,
                    color: hasLocation
                        ? ColorManager.primary
                        : ColorManager.descriptionColor,
                  ),
                  SizedBox(width: AppPadding.p8),
                  Expanded(
                    child: isLoading
                        ? CustomText(
                            text: useMyLocationHint,
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s14,
                              color: ColorManager.descriptionColor,
                            ).copyWith(height: 1.15),
                          )
                        : hasLocation
                        ? ResolvedAddressCaption(
                            country: displayCountry,
                            city: displayCity,
                            street: displayStreet,
                            fallbackLine: locationSetFallbackHint,
                            latitude: latitude!,
                            longitude: longitude!,
                            compactSingleLine: true,
                          )
                        : CustomText(
                            text: useMyLocationHint,
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s14,
                              color: ColorManager.descriptionColor,
                            ).copyWith(height: 1.15),
                          ),
                  ),
                  if (hasLocation && onClearLocation != null)
                    IconButton(
                      onPressed: onClearLocation,
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: ColorManager.descriptionColor,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    )
                  else if (!hasLocation && !isLoading)
                    Icon(
                      Icons.arrow_drop_down,
                      color: ColorManager.descriptionColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

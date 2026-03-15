import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// A dropdown-style container for "Use my location" during registration.
/// Matches the look of [CustomPaginatedDropdown] / [CustomDropdown].
class LocationSourceSelector extends StatelessWidget {
  final String title;
  final String useMyLocationHint;
  final String locationSetHint;
  final double? latitude;
  final double? longitude;
  final bool isRequired;
  final VoidCallback onUseMyLocation;
  final VoidCallback? onClearLocation;
  final bool isLoading;

  const LocationSourceSelector({
    super.key,
    required this.title,
    required this.useMyLocationHint,
    required this.locationSetHint,
    this.latitude,
    this.longitude,
    this.isRequired = false,
    required this.onUseMyLocation,
    this.onClearLocation,
    this.isLoading = false,
  });

  bool get hasLocation =>
      latitude != null && longitude != null;

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
        GestureDetector(
          onTap: hasLocation || isLoading ? null : onUseMyLocation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: AppHeight.s56,
            padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
            decoration: BoxDecoration(
              color: ColorManager.defaultWhite,
              borderRadius: BorderRadius.circular(AppRadius.r18),
              border: Border.all(
                color: ColorManager.borderColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasLocation ? Icons.location_on : Icons.my_location,
                  size: 22,
                  color: hasLocation
                      ? ColorManager.primary
                      : ColorManager.descriptionColor,
                ),
                SizedBox(width: AppPadding.p12),
                Expanded(
                  child: isLoading
                      ? CustomText(
                          text: useMyLocationHint,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s14,
                            color: ColorManager.descriptionColor,
                          ),
                        )
                      : CustomText(
                          text: hasLocation
                              ? locationSetHint
                                  .replaceAll('{lat}', latitude!.toStringAsFixed(5))
                                  .replaceAll('{lng}', longitude!.toStringAsFixed(5))
                              : useMyLocationHint,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s14,
                            color: hasLocation
                                ? ColorManager.productNameColor
                                : ColorManager.descriptionColor,
                          ),
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
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
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
      ],
    );
  }
}

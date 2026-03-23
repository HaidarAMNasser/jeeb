import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

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
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text:
                '${AppTranslation.selectedLocation}: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
            textStyle: getRegularStyle(
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
            if ((country ?? '').isNotEmpty)
              _LocationLine(
                label: AppTranslation.country,
                value: country!,
                topSpacing: AppHeight.s5,
              ),
            if ((city ?? '').isNotEmpty)
              _LocationLine(
                label: AppTranslation.city,
                value: city!,
                topSpacing: AppHeight.s4,
              ),
            if ((street ?? '').isNotEmpty)
              _LocationLine(
                label: AppTranslation.street,
                value: street!,
                topSpacing: AppHeight.s4,
              ),
          ],
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  final String label;
  final String value;
  final double topSpacing;

  const _LocationLine({
    required this.label,
    required this.value,
    required this.topSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: CustomText(
        text: '$label: $value',
        textStyle: getRegularStyle(
          fontSize: AppFontSize.s13,
          color: ColorManager.productNameColor,
        ),
      ),
    );
  }
}

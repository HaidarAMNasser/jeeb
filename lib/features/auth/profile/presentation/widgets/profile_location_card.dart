import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';

import 'package:jeeb_app/core/infrastructure/services/location_services/location_map_picker_page.dart';

/// Displays user's current location from profile and allows updating via map picker.
class ProfileLocationCard extends StatelessWidget {
  const ProfileLocationCard({
    super.key,
    required this.user,
    required this.onLocationPicked,
  });

  final UserEntity user;
  final void Function(double latitude, double longitude) onLocationPicked;

  bool get _hasLocation =>
      user.currentLat != null && user.currentLng != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: ColorManager.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 22,
                color: ColorManager.primary,
              ),
              SizedBox(width: AppPadding.p8),
              CustomText(
                text: AppTranslation.currentLocation,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.productNameColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppHeight.s12),
          CustomText(
            text: _hasLocation
                ? '${AppTranslation.latitude}: ${user.currentLat!.toStringAsFixed(5)}\n${AppTranslation.longitude}: ${user.currentLng!.toStringAsFixed(5)}'
                : AppTranslation.noLocationSet,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: _hasLocation
                  ? ColorManager.productNameColor
                  : ColorManager.descriptionColor,
            ),
          ),
          SizedBox(height: AppHeight.s16),
          SizedBox(
            height: AppHeight.s48,
            child: OutlinedButton.icon(
              onPressed: () => _openMapPicker(context),
              icon: Icon(Icons.map, size: 20, color: ColorManager.primary),
              label: CustomText(
                text: AppTranslation.updateLocation,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorManager.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.r18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<LocationMapPickerResult>(
      MaterialPageRoute(
        builder: (context) => LocationMapPickerPage(
          initialLatitude: user.currentLat,
          initialLongitude: user.currentLng,
        ),
      ),
    );
    if (result != null && context.mounted) {
      onLocationPicked(result.latitude, result.longitude);
    }
  }
}

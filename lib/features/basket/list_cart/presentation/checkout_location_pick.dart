import 'package:flutter/material.dart';
import 'package:jeeb_app/core/common/utils/map_defaults.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_choice_dialog.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_map_picker_page.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_permission_helper.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

/// Dialog (current vs map) then GPS or map picker. Returns `null` if cancelled.
Future<({double lat, double lng})?> pickCheckoutLocation(
  BuildContext context,
) async {
  final action = await showDialog<LocationChoice>(
    context: context,
    builder: (_) => const LocationChoiceDialog(),
  );
  if (action == null) return null;

  double? lat;
  double? lng;

  if (action == LocationChoice.current) {
    final res = await LocationPermissionHelper.requestAndGetPosition();
    lat = res.latitude;
    lng = res.longitude;
    if (lat == null || lng == null) {
      if (context.mounted) {
        customToast(msg: AppTranslation.locationUnavailable);
      }
      return null;
    }
  } else {
    final picked = await Navigator.of(context).push<LocationMapPickerResult>(
      MaterialPageRoute(
        builder: (_) => const LocationMapPickerPage(
          initialLatitude: MapDefaults.latitude,
          initialLongitude: MapDefaults.longitude,
        ),
      ),
    );
    if (picked == null) return null;
    lat = picked.latitude;
    lng = picked.longitude;
  }

  return (lat: lat, lng: lng);
}
//
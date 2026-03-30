import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Read-only map: centers on [deliveryLatitude]/[deliveryLongitude] when set,
/// and shows the driver at [driverLatitude]/[driverLongitude] when available.
class LiveTrackingMapCard extends StatelessWidget {
  const LiveTrackingMapCard({
    super.key,
    required this.title,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverLatitude,
    this.driverLongitude,
    this.statusLabel,
    this.statusOnline,
    this.height = 220,
  }) : assert(
          (deliveryLatitude != null && deliveryLongitude != null) ||
              (driverLatitude != null && driverLongitude != null),
        );

  final String title;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? driverLatitude;
  final double? driverLongitude;
  final String? statusLabel;
  final bool? statusOnline;
  final double height;

  LatLng? get _delivery {
    final lat = deliveryLatitude;
    final lng = deliveryLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _driver {
    final lat = driverLatitude;
    final lng = driverLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  /// Camera target: drop-off first, else courier (matches “show destination first”).
  LatLng get _cameraTarget => _delivery ?? _driver!;

  @override
  Widget build(BuildContext context) {
    final chipColor = (statusOnline ?? false) ? ColorManager.defaultBlue : Colors.orange;
    final markers = <Marker>{};
    final d = _delivery;
    if (d != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_delivery_marker'),
          position: d,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    final drv = _driver;
    if (drv != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_driver_marker'),
          position: drv,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: ColorManager.primary),
              SizedBox(width: AppWidth.s8),
              Expanded(
                child: CustomText(
                  text: title,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.productNameColor,
                  ),
                ),
              ),
              if (statusLabel != null && statusLabel!.trim().isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p10,
                    vertical: AppPadding.p4,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    border: Border.all(color: chipColor.withValues(alpha: 0.45)),
                  ),
                  child: CustomText(
                    text: statusLabel!,
                    textStyle: getMediumStyle(
                      fontSize: AppFontSize.s11,
                      color: chipColor,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppHeight.s10),
          SizedBox(
            width: double.infinity,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _cameraTarget,
                  zoom: 15.2,
                ),
                markers: markers,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

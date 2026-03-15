import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jeeb_app/core/common/utils/location_permission_helper.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart' show customToast;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:latlong2/latlong.dart';

/// Default center when no initial location (Cairo).
const LatLng _defaultCenter = LatLng(30.0444, 31.2357);

/// Result returned when user confirms location.
class LocationMapPickerResult {
  const LocationMapPickerResult({
    required this.latitude,
    required this.longitude,
  });
  final double latitude;
  final double longitude;
}

/// Full-screen map to pick a location. Tap to set marker, confirm to return lat/lng.
class LocationMapPickerPage extends StatefulWidget {
  const LocationMapPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationMapPickerPage> createState() => _LocationMapPickerPageState();
}

class _LocationMapPickerPageState extends State<LocationMapPickerPage> {
  final MapController _mapController = MapController();
  late LatLng _selectedPoint;
  static const double _zoom = 14;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
    } else {
      _selectedPoint = _defaultCenter;
    }
  }

  LatLng get _initialCenter => _selectedPoint;

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPoint = point);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    final position = await LocationPermissionHelper.requestAndGetPosition();
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);
    if (position != null) {
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _selectedPoint = point);
      _mapController.move(point, _zoom);
    } else if (mounted) {
      customToast(msg: AppTranslation.locationPermissionDenied);
    }
  }

  void _onConfirm() {
    Navigator.of(context).pop(
      LocationMapPickerResult(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.chooseLocationOnMap),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 14,
                onTap: _onMapTap,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.jeeb.jeeb_admin',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.location_on,
                        size: 48,
                        color: ColorManager.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(AppPadding.p24),
            color: ColorManager.background,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomText(
                    text:
                        '${AppTranslation.latitude}: ${_selectedPoint.latitude.toStringAsFixed(5)}\n${AppTranslation.longitude}: ${_selectedPoint.longitude.toStringAsFixed(5)}',
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.textColor,
                    ),
                  ),
                  SizedBox(height: AppHeight.s16),
                  CustomButton(
                    text: AppTranslation.useMyLocation,
                    onPressed: _goToMyLocation,
                    isLoading: _isLoadingLocation,
                    color: ColorManager.primary,
                    isOutlined: true,
                  ),
                  SizedBox(height: AppHeight.s12),
                  CustomButton(
                    text: AppTranslation.confirm,
                    onPressed: _onConfirm,
                    color: ColorManager.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

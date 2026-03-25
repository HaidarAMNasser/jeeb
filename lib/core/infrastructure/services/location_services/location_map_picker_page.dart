import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart' show customToast;
import 'package:jeeb_app/core/infrastructure/services/location_services/location_permission_helper.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Default center when no device location (Cairo).
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

/// Full-screen **Google** map to pick a location. Tap to set marker, confirm to return lat/lng.
/// Opens centered on [initialLatitude]/[initialLongitude] if provided; otherwise
/// tries device location (silent first, then permission flow).
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
  GoogleMapController? _mapController;
  late LatLng _selectedPoint;
  static const double _zoom = 16;
  bool _isLoadingLocation = false;
  bool _didApplyInitialDevice = false;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusInitialOnDevice();
      });
    }
  }

  Future<void> _focusInitialOnDevice() async {
    if (_didApplyInitialDevice || !mounted) return;
    _didApplyInitialDevice = true;

    setState(() => _isLoadingLocation = true);

    LatLng? point;
    final silent = await LocationPermissionHelper.trySilentPosition();
    if (silent != null) {
      point = LatLng(silent.latitude, silent.longitude);
    } else {
      final res = await LocationPermissionHelper.requestAndGetPosition();
      if (res.latitude != null && res.longitude != null) {
        point = LatLng(res.latitude!, res.longitude!);
      }
    }

    if (!mounted) return;
    setState(() => _isLoadingLocation = false);

    if (point != null) {
      setState(() => _selectedPoint = point!);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(point, _zoom),
      );
    }
  }

  void _onMapTap(LatLng point) {
    setState(() => _selectedPoint = point);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    final result = await LocationPermissionHelper.requestAndGetPosition();
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);
    if (result.latitude != null && result.longitude != null) {
      final point = LatLng(result.latitude!, result.longitude!);
      setState(() => _selectedPoint = point);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(point, _zoom),
      );
    } else if (mounted) {
      customToast(
        msg: result.permissionGranted
            ? AppTranslation.locationUnavailable
            : AppTranslation.locationPermissionDenied,
      );
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
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPoint,
                zoom: _zoom,
              ),
              onMapCreated: (c) {
                _mapController = c;
                if (widget.initialLatitude == null ||
                    widget.initialLongitude == null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedPoint, _zoom),
                  );
                }
              },
              onTap: _onMapTap,
              markers: {
                Marker(
                  markerId: const MarkerId('pick'),
                  position: _selectedPoint,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
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

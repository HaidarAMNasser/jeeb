import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

/// Default map center (Cairo) when order has no coordinates yet.
const LatLng _kDefaultMapCenter = LatLng(30.0444, 31.2357);

/// Read-only Google Map preview for the order address (live tracking later).
class OrderDeliveryMapPreview extends StatelessWidget {
  const OrderDeliveryMapPreview({super.key, this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final target = (latitude != null && longitude != null)
        ? LatLng(latitude!, longitude!)
        : _kDefaultMapCenter;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: SizedBox(
        height: 220.h,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 14.5),
          markers: {
            Marker(
              markerId: const MarkerId('order_destination'),
              position: target,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          liteModeEnabled: false,
        ),
      ),
    );
  }
}

/// Wraps [OrderDeliveryMapPreview] with map + delivery status badges (live tracking later).
class OrderDeliveryMapSection extends StatelessWidget {
  const OrderDeliveryMapSection({
    super.key,
    required this.mapBadgeLabel,
    required this.deliveryStatus,
    required this.latitude,
    required this.longitude,
  });

  final String mapBadgeLabel;
  final OrderStatus deliveryStatus;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final c = deliveryStatus.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p18,
            vertical: AppPadding.p14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorManager.primary.withValues(alpha: 0.12),
                ColorManager.defaultWhite,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.r20),
            border: Border.all(
              color: ColorManager.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorManager.primary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.map_rounded,
                color: ColorManager.primary,
                size: AppSize.s28,
              ),
              SizedBox(width: AppWidth.s12),
              Expanded(
                child: CustomText(
                  text: mapBadgeLabel,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: ColorManager.productNameColor,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppHeight.s10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p18,
            vertical: AppPadding.p12,
          ),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(AppRadius.r18),
            border: Border.all(color: c.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(deliveryStatus.iconData, color: c, size: AppSize.s26),
              SizedBox(width: AppWidth.s12),
              Expanded(
                child: CustomText(
                  text: deliveryStatus.displayLabel,
                  textStyle: getBoldStyle(fontSize: AppFontSize.s16, color: c),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppHeight.s12),
        OrderDeliveryMapPreview(latitude: latitude, longitude: longitude),
      ],
    );
  }
}

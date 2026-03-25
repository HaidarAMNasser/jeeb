import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/address_geocoding.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Read-only address + coordinates (shared UI).
class ResolvedAddressCaption extends StatelessWidget {
  final String? country;
  final String? city;
  final String? street;
  final String fallbackLine;
  final double latitude;
  final double longitude;
  /// Single line with middle dots; long text ellipsized.
  final bool compactSingleLine;

  const ResolvedAddressCaption({
    super.key,
    required this.country,
    required this.city,
    required this.street,
    required this.fallbackLine,
    required this.latitude,
    required this.longitude,
    this.compactSingleLine = false,
  });

  bool get _hasLines {
    final c = country?.trim() ?? '';
    final ct = city?.trim() ?? '';
    final s = street?.trim() ?? '';
    return c.isNotEmpty || ct.isNotEmpty || s.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (compactSingleLine) {
      return CustomText(
        text: AddressGeocoding.formatDisplayLine(
          country: country,
          city: city,
          street: street,
          fallbackIfEmpty: fallbackLine,
          latitude: latitude,
          longitude: longitude,
        ),
        textStyle: getRegularStyle(
          fontSize: AppFontSize.s14,
          color: ColorManager.productNameColor,
        ).copyWith(height: 1.15),
        maxLines: 1,
        textOverflow: TextOverflow.ellipsis,
      );
    }

    final children = <Widget>[];

    void addLine(String text) {
      final t = text.trim();
      if (t.isEmpty) return;
      children.add(
        CustomText(
          text: t,
          textStyle: getRegularStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.productNameColor,
          ),
        ),
      );
    }

    if (_hasLines) {
      addLine(country ?? '');
      addLine(city ?? '');
      addLine(street ?? '');
    } else {
      addLine(fallbackLine);
    }

    children.add(
      CustomText(
        text:
            '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
        textStyle: getRegularStyle(
          fontSize: AppFontSize.s12,
          color: ColorManager.descriptionColor,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: AppHeight.s4),
          children[i],
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/common/utils/asset_manager.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';

/// Fallback cover when a merchant has no image or the network image fails.
class MerchantDefaultCoverImage extends StatelessWidget {
  const MerchantDefaultCoverImage({
    super.key,
    this.height,
    this.width,
    this.fillParent = false,
  }) : assert(
          fillParent || height != null,
          'Provide height or set fillParent: true',
        );

  /// Fixed height (e.g. list row banner).
  final double? height;

  final double? width;

  /// Fills parent (e.g. [Expanded] image area on home merchant card).
  final bool fillParent;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      ImageAsset.defaultMarchent,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      width: fillParent ? null : width,
      height: fillParent ? null : height,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: ColorManager.background,
        child: Icon(
          Icons.storefront_rounded,
          color: ColorManager.primary.withValues(alpha: 0.5),
          size: (height ?? 80) * 0.35,
        ),
      ),
    );

    if (fillParent) {
      return SizedBox.expand(child: image);
    }
    return SizedBox(width: width, height: height, child: image);
  }
}

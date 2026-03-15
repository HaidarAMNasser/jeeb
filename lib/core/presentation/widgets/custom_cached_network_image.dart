import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable cached network image with shimmer loading placeholder.
/// Use for product listing, order listing, delivery, merchants, profile, etc.
class CustomCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;

  const CustomCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => _ShimmerPlaceholder(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
      errorWidget: (_, __, ___) =>
          errorWidget ?? _defaultErrorWidget(width: width, height: height),
    );
    if (borderRadius != null) {
      child = ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }

  static Widget _defaultErrorWidget({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: ColorManager.background,
      child: Icon(
        Icons.broken_image_outlined,
        color: ColorManager.defaultWhite.withOpacity(0.4),
        size: AppSize.s40,
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _ShimmerPlaceholder({
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ColorManager.defaultWhite.withOpacity(0.12),
      highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: ColorManager.defaultWhite.withOpacity(0.2),
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
      ),
    );
  }
}

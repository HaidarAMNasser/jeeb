import 'package:flutter/material.dart';
import 'package:jeeb_app/core/common/utils/asset_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';

/// Background layer: product image, [ImageAsset.offerDefault] if missing/error, + dark overlay.
class OfferCardBackground extends StatelessWidget {
  const OfferCardBackground({super.key, this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildLayer(),
        _buildOverlay(),
      ],
    );
  }

  Widget _buildLayer() {
    final fallback = Image.asset(
      ImageAsset.offerDefault,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CustomCachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: fallback,
      );
    }
    return fallback;
  }

  Widget _buildOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.75),
          ],
        ),
      ),
    );
  }
}

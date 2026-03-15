import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';

/// Background layer for offer card: image or gradient, with dark overlay.
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
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CustomCachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary.withOpacity(0.9),
            ColorManager.secondary.withOpacity(0.8),
          ],
        ),
      ),
    );
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

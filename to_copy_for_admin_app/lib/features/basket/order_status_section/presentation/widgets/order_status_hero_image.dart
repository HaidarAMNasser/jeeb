import 'package:flutter/material.dart';
import 'package:jeeb_app/core/common/utils/asset_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

/// Hero card: step image fills the **entire** rounded card (edge to edge).
class OrderStatusHeroImage extends StatelessWidget {
  const OrderStatusHeroImage({super.key, required this.timelineStepIndex});

  final int timelineStepIndex;

  @override
  Widget build(BuildContext context) {
    final idx = timelineStepIndex.clamp(0, 6);
    final path = ImageAsset.timelineStepImagePath(idx);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft  : Radius.circular(AppRadius.r60),
        bottomRight: Radius.circular(AppRadius.r60),
      ),
      child: AspectRatio(
        aspectRatio: 1.15,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              path,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.05,
                  colors: [Color(0x00000000), Color(0x332E2C2A)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

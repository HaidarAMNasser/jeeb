import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/offer/offer_card_background.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/offer/offer_card_content.dart';

/// Offer card for home slider: product image background, overlay with title, merchant, discount.
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.onTap,
  });

  final OfferEntity offer;
  final VoidCallback onTap;

  static String? _firstProductImageUrl(OfferEntity offer) {
    for (final p in offer.products) {
      if (p.images.isNotEmpty) {
        final img = p.images.first;
        return img.mobileUrl ?? img.thumbnailUrl ?? img.url;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPercentage =
        (offer.discountType ?? 'PERCENTAGE').toUpperCase() == 'PERCENTAGE';
    final discountValue = (offer.discountValue ?? 0).toInt();
    final discountText = isPercentage
        ? AppTranslation.percentOffN(discountValue)
        : AppTranslation.amountOffN(discountValue.toString());

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.p6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          child: SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                OfferCardBackground(imageUrl: _firstProductImageUrl(offer)),
                OfferCardContent(offer: offer, discountText: discountText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

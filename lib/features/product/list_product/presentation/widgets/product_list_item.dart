import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/common/utils/asset_manager.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_item_image_carousel.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_item_info.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_item_actions.dart';

/// Heart icon that toggles color instantly on tap (local state only).
class _FavoriteHeartIcon extends StatefulWidget {
  final bool initialFavorite;
  final VoidCallback onTap;

  const _FavoriteHeartIcon({
    required this.initialFavorite,
    required this.onTap,
  });

  @override
  State<_FavoriteHeartIcon> createState() => _FavoriteHeartIconState();
}

class _FavoriteHeartIconState extends State<_FavoriteHeartIcon> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialFavorite;
  }

  void _onTap() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.red,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class ProductListItem extends StatelessWidget {
  final ProductEntity product;
  final bool enableSmallDesign;
  final bool showConfirmProduct;
  final bool isFavorite;
  final bool isTogglingFavorite;
  final VoidCallback? onToggleFavorite;

  const ProductListItem({
    super.key,
    required this.product,
    this.enableSmallDesign = true,
    this.showConfirmProduct = false,
    this.isFavorite = false,
    this.isTogglingFavorite = false,
    this.onToggleFavorite,
  });

  bool get _isOfferItem => product.id.startsWith('offer_');

  String get _offerId => product.id.replaceFirst('offer_', '');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (_isOfferItem && _offerId.isNotEmpty) {
          AppRouter.navigateTo(
            context,
            Routes.offerDetails,
            arguments: {'offerId': _offerId},
          );
          return;
        }
        AppRouter.navigateTo(
          context,
          Routes.productDetails,
          arguments: {'productId': product.id, 'tabIndexOnBack': 0},
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProductItemImageCarousel(
                key: ValueKey('${product.id}_${product.images.length}'),
                images: product.images,
                enableSmallDesign: enableSmallDesign,
                placeholderAsset: ImageAsset.defaultMarchent,
              ),
              if (onToggleFavorite != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _FavoriteHeartIcon(
                    initialFavorite: isFavorite,
                    onTap: onToggleFavorite!,
                  ),
                ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(bottom: AppMargin.m16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: ColorManager.defaultWhite,

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.r16),
                bottomRight: Radius.circular(AppRadius.r16),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppPadding.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductItemInfo(
                    enableSmallDesign: enableSmallDesign,
                    product: product,
                  ),
                  ProductItemActions(
                    enableSmallDesign: enableSmallDesign,
                    productId: product.id,
                    price: product.price,
                    displayPrice:
                        product.finalPrice ??
                        product.priceAfterDiscount ??
                        product.price,
                    commissionRate: product.commissionRate,
                    showConfirmProduct: showConfirmProduct,
                    stockQuantity: product.stockQuantity,
                    hasStock: product.hasStock,
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

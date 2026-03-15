import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';

class ProductDetailsImageGallery extends StatelessWidget {
  final List<ProductImageEntity> images;

  const ProductDetailsImageGallery({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width;
    const height = 240.0;
    return SizedBox(
      height: height,
      width: width,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => SizedBox(width: AppPadding.p12),
        itemBuilder: (context, index) {
          final img = images[index];
          final url = img.thumbnailUrl ?? img.mobileUrl ?? img.url;
          if (url.isEmpty) return const SizedBox.shrink();
          return SizedBox(
            width: width,
            height: height,
            child: CustomCachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              width: width,
              height: height,
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductItemImageCarousel extends StatefulWidget {
  final List<ProductImageEntity> images;
  final bool enableSmallDesign; 

  const ProductItemImageCarousel({super.key, required this.images, this.enableSmallDesign = false});

  @override
  State<ProductItemImageCarousel> createState() =>
      _ProductItemImageCarouselState();
}

class _ProductItemImageCarouselState extends State<ProductItemImageCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;
    final itemCount = hasImages ? widget.images.length : 1;

    return SizedBox(
      height: widget.enableSmallDesign ? 100.h : 150.h,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: itemCount,
            itemBuilder: (context, index) =>
                _ImagePage(url: hasImages ? widget.images[index].url : null),
          ),
          if (itemCount > 1)
            _CarouselDots(count: itemCount, currentIndex: _currentPage),
        ],
      ),
    );
  }
}

class _ImagePage extends StatelessWidget {
  final String? url;

  const _ImagePage({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppRadius.r12),
        topRight: Radius.circular(AppRadius.r12),
      ),
      child: Container(
        width: double.infinity,
        color: ColorManager.background,
        child: url != null
            ? CustomCachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: const _PlaceholderImage(),
              )
            : const _PlaceholderImage(),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image,
        color: ColorManager.defaultWhite.withOpacity(0.3),
        size: AppSize.s50,
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _CarouselDots({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: AppHeight.s8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: AppSize.s3),
            width: currentIndex == index ? AppSize.s10 : AppSize.s5,
            height: AppSize.s5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index
                  ? ColorManager.primary
                  : ColorManager.defaultWhite.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }
}

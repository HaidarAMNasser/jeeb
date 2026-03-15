import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_cubit.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_state.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';

/// Slider showing 3 offer cards at a time; middle one is bigger. Auto-advances.
class ClientHomeOffersSlider extends StatefulWidget {
  const ClientHomeOffersSlider({super.key});

  @override
  State<ClientHomeOffersSlider> createState() => _ClientHomeOffersSliderState();
}

class _ClientHomeOffersSliderState extends State<ClientHomeOffersSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final cubit = context.read<ClientHomeCubit>();
      final state = cubit.state;
      final offers = state.offers ?? [];
      if (offers.isEmpty) return;
      final current = _pageController.page?.round() ?? 0;
      final next = (current + 1) % offers.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientHomeCubit, ClientHomeState>(
      buildWhen: (a, b) => a.offers != b.offers,
      builder: (context, state) {
        final offers = state.offers ?? const [];
        if (offers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Offers',
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
            ),
            SizedBox(height: AppHeight.s16),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                      }
                      return Transform.scale(
                        scale: 0.85 + (0.15 * value),
                        child: child,
                      );
                    },
                    child: _OfferCard(offer: offers[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final OfferEntity offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.p6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorManager.primary.withValues(alpha: 0.9),
              ColorManager.secondary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: [
            BoxShadow(
              color: ColorManager.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              text: offer.shortDescription ?? offer.longDescription ?? 'Offer',
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.defaultWhite,
              ),
              maxLines: 2,
              textOverflow: TextOverflow.ellipsis,
            ),
            if (offer.longDescription != null && offer.longDescription != offer.shortDescription) ...[
              SizedBox(height: AppHeight.s4),
              CustomText(
                text: offer.longDescription!,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.defaultWhite.withValues(alpha: 0.9),
                ),
                maxLines: 1,
                textOverflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: AppHeight.s8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p12,
                vertical: AppPadding.p4,
              ),
              decoration: BoxDecoration(
                color: ColorManager.defaultWhite.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: CustomText(
                text: (offer.discountType ?? 'PERCENTAGE').toUpperCase() == 'PERCENTAGE'
                    ? '${(offer.discountValue ?? 0).toInt()}% off'
                    : '${(offer.discountValue ?? 0).toInt()} off',
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.defaultWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

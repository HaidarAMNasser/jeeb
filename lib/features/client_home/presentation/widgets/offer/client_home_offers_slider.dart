import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/offer/offer_card.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/offer/offers_shimmer.dart';

/// Slider showing offer cards; middle one is bigger. Auto-advances.
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
      final bloc = context.read<ClientHomeBloc>();
      final state = bloc.state;
      final offers = state.offers ?? [];
      if (offers.isEmpty || !_pageController.hasClients) return;
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
    return BlocBuilder<ClientHomeBloc, ClientHomeState>(
      buildWhen: (a, b) =>
          a.isOffersLoading != b.isOffersLoading || a.offers != b.offers,
      builder: (context, state) {
        if (state.isOffersLoading) {
          return const OffersShimmer();
        }

        final offers = state.offers ?? const [];
        if (offers.isEmpty) {
          if (state.isSearchActive) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: AppTranslation.offers,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s18,
                    color: ColorManager.titlesColor,
                  ),
                ),
                SizedBox(height: AppHeight.s16),
                Center(
                  child: CustomText(
                    text: AppTranslation.noResultsFound,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: AppTranslation.offers,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s18,
                    color: ColorManager.titlesColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppRouter.navigateTo(context, Routes.offers);
                  },
                  child: CustomText(
                    text: AppTranslation.showAll,
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.primary,
                    ),
                  ),
                ),
              ],
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
                    child: OfferCard(
                      offer: offers[index],
                      onTap: () {
                        AppRouter.navigateTo(
                          context,
                          Routes.offerDetails,
                          arguments: {'offerId': offers[index].id},
                        );
                      },
                    ),
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

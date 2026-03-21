import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/merchants/merchant_card.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/merchants/merchants_shimmer.dart';

/// Merchants/restaurants as bigger rectangular cards with image and name. View more → list merchants.
class ClientHomeMerchantsSection extends StatelessWidget {
  const ClientHomeMerchantsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientHomeBloc, ClientHomeState>(
      buildWhen: (a, b) =>
          a.isMerchantsLoading != b.isMerchantsLoading ||
          a.merchants != b.merchants,
      builder: (context, state) {
        if (state.isMerchantsLoading) {
          return const MerchantsShimmer();
        }

        final merchants = state.merchants;
        if (merchants.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: AppTranslation.merchants,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s18,
                    color: ColorManager.titlesColor,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppRouter.navigateTo(context, Routes.merchants);
                  },
                  child: CustomText(
                    text: 'View more',
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppHeight.s12),
            SizedBox(
              height: AppHeight.s136,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: merchants.length,
                separatorBuilder: (_, __) => SizedBox(width: AppPadding.p12),
                itemBuilder: (context, index) {
                  return MerchantCard(merchant: merchants[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

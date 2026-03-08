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
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_cubit.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_state.dart';

/// Merchants/restaurants as bigger rectangular cards with image and name. View more → list merchants.
class ClientHomeMerchantsSection extends StatelessWidget {
  const ClientHomeMerchantsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientHomeCubit, ClientHomeState>(
      buildWhen: (a, b) => a.merchants != b.merchants,
      builder: (context, state) {
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
                  return _MerchantCard(merchant: merchants[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MerchantCard extends StatelessWidget {
  final MerchantEntity merchant;

  const _MerchantCard({required this.merchant});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppRouter.navigateTo(
          context,
          Routes.merchantDetails,
          arguments: {'merchantId': merchant.id},
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.r16),
                ),
                child: merchant.image != null && merchant.image!.isNotEmpty
                    ? Image.network(
                        merchant.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.p8,
                  vertical: AppPadding.p4,
                ),
                child: Center(
                  child: CustomText(
                    text: merchant.name,
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.productNameColor,
                    ),
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: ColorManager.background,
      child: Icon(
        Icons.store,
        color: ColorManager.primary.withOpacity(0.5),
        size: 40,
      ),
    );
  }
}

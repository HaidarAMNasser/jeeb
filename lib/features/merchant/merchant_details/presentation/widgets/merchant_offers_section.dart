import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/offer/list_offer/presentation/bloc/list_offer_bloc.dart';
import 'package:jeeb_app/features/offer/list_offer/presentation/widgets/offer_list_item.dart';

const int _kMerchantOffersPreviewLimit = 3;

class MerchantOffersSection extends StatelessWidget {
  final String merchantId;

  const MerchantOffersSection({
    super.key,
    required this.merchantId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListOfferBloc, ListOfferState>(
      builder: (context, state) {
        if (state is ListOfferLoading || state is ListOfferInitial) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: AppTranslation.offers,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s20,
                  color: ColorManager.titlesColor,
                ),
              ),
              SizedBox(height: AppHeight.s16),
               Center(
                child: Padding(
                  padding: EdgeInsets.all(AppPadding.p24),
                  child: CustomCircleIndicator(),
                ),
              ),
            ],
          );
        }

        if (state is ListOfferError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: AppTranslation.offers,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s20,
                  color: ColorManager.titlesColor,
                ),
              ),
              SizedBox(height: AppHeight.s16),
              CustomText(
                text: state.message,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.error,
                ),
              ),
              SizedBox(height: AppHeight.s12),
              CustomButton(
                text: AppTranslation.retry,
                onPressed: () {
                  context.read<ListOfferBloc>().add(
                    GetOffersEvent(merchantId: merchantId),
                  );
                },
                color: ColorManager.primary,
              ),
            ],
          );
        }

        final offerList = state is ListOfferLoaded
            ? state.offers
            : (state is ListOfferLoadingMore)
                ? state.offers
                : <OfferEntity>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CustomText(
                  text: AppTranslation.offers,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s20,
                    color: ColorManager.titlesColor,
                  ),
                ),
                if (offerList.isNotEmpty)
                  InkWell(
                    onTap: () {
                      context.pushNamed(
                        Routes.offers,
                        arguments: {'merchantId': merchantId},
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppPadding.p8,
                        vertical: AppPadding.p4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: AppTranslation.showAll,
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s14,
                              color: ColorManager.defaultWhite,
                            ),
                          ),
                          SizedBox(width: AppWidth.s4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: AppSize.s20,
                            color: ColorManager.defaultWhite,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppHeight.s16),
            if (offerList.isEmpty)
              CustomText(
                text: AppTranslation.noOffersFound,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.descriptionColor,
                ),
              )
            else
              ...offerList.take(_kMerchantOffersPreviewLimit).map(
                    (o) => OfferListItem(offer: o),
                  ),
          ],
        );
      },
    );
  }
}

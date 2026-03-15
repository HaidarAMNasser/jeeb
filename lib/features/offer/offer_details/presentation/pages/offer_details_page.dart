import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:jeeb_app/features/offer/offer_details/presentation/bloc/offer_details_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/widgets.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';

class OfferDetailsPage extends StatefulWidget {
  final String offerId;

  const OfferDetailsPage({super.key, required this.offerId});

  @override
  State<OfferDetailsPage> createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<OfferDetailsBloc>().add(
      GetOfferDetailsEvent(id: widget.offerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.offerDetails),
      body: BlocStateHandler<OfferDetailsBloc, OfferDetailsState>(
        bloc: context.read<OfferDetailsBloc>(),
        isLoading: (state) => state is OfferDetailsLoading,
        isError: (state) => state is OfferDetailsError,
        getErrorMessage: (state) => (state as OfferDetailsError).message,
        isSuccess: (state) => state is OfferDetailsLoaded,
        getRetryCallback: (_) => () {
          context.read<OfferDetailsBloc>().add(
            GetOfferDetailsEvent(id: widget.offerId),
          );
        },
        successBuilder: (context, offerState) {
          final offer = (offerState as OfferDetailsLoaded).offer;
          final discountLabel =
              '${offer.discountValue} ${offer.discountType == 'PERCENTAGE' ? '%' : ''}';

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppPadding.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.shortDescription != null) ...[
                  CustomText(
                    text: offer.shortDescription!,
                    textStyle: getBoldStyle(
                      fontSize: AppFontSize.s20,
                      color: ColorManager.defaultWhite,
                    ),
                  ),
                  SizedBox(height: AppHeight.s8),
                ],
                if (offer.longDescription != null) ...[
                  CustomText(
                    text: offer.longDescription!,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppHeight.s16),
                ],
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p12,
                    vertical: AppPadding.p8,
                  ),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: CustomText(
                    text: '${AppTranslation.offerDiscount}: $discountLabel',
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.primary,
                    ),
                  ),
                ),
                SizedBox(height: AppHeight.s12),
                Row(
                  children: [
                    Expanded(
                      child: CustomDateSelect(
                        title: AppTranslation.offerStartDate,
                        initialValue: offer.startDate,
                        onDateSelected: (_) {},
                        isDisabled: true,
                      ),
                    ),
                    SizedBox(width: AppWidth.s16),
                    Expanded(
                      child: CustomDateSelect(
                        title: AppTranslation.offerEndDate,
                        initialValue: offer.endDate,
                        onDateSelected: (_) {},
                        isDisabled: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppHeight.s16),
                CustomText(
                  text: AppTranslation.offerProductsCount,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: ColorManager.defaultWhite,
                  ),
                ),
                SizedBox(height: AppHeight.s8),
                ...offer.products.map((p) => ProductListItem(product: p)),
                SizedBox(height: AppHeight.s24),
                // Edit button: merchant only; hidden for admin
                FutureBuilder<String?>(
                  future: di.sl<StorageService>().getUserRole(),
                  builder: (context, snapshot) {
                    final isAdmin =
                        snapshot.data?.toLowerCase() == UserRole.admin.name;
                    if (isAdmin) return const SizedBox.shrink();
                    return CustomButton(
                      text: AppTranslation.editOffer,
                      onPressed: () {
                        context.pushReplacementNamed(
                          Routes.addOffer,
                          arguments: {'offer': offer},
                        );
                      },
                      color: ColorManager.primary,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

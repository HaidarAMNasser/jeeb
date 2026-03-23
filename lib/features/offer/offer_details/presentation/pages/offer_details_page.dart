import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/features/basket/manage_cart/presentation/bloc/manage_cart_bloc.dart';
import 'package:jeeb_app/features/offer/offer_details/presentation/bloc/offer_details_bloc.dart';
import 'package:jeeb_app/features/offer/offer_details/presentation/widgets/offer_details_content.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/widgets.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

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
    return BlocConsumer<ManageCartBloc, ManageCartState>(
      listener: (context, state) {
        if (state is ManageCartSuccess) {
          customToast(msg: AppTranslation.addedToCart);
        } else if (state is ManageCartError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, cartState) {
        return ModalProgressHUD(
          inAsyncCall: cartState is ManageCartLoading,
          progressIndicator: const CircularProgressIndicator(
            color: ColorManager.primary,
          ),
          child: Scaffold(
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
                return OfferDetailsContent(offer: offer);
              },
            ),
            bottomNavigationBar:
                BlocBuilder<OfferDetailsBloc, OfferDetailsState>(
              builder: (context, offerState) {
                if (offerState is! OfferDetailsLoaded) {
                  return const SizedBox.shrink();
                }
                final offer = offerState.offer;
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppPadding.p16,
                      0,
                      AppPadding.p16,
                      AppPadding.p16,
                    ),
                    child: SizedBox(
                      height: AppHeight.s56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          context.read<ManageCartBloc>().add(
                                AddOfferToCartEvent(offer.id),
                              );
                        },
                        icon: const Icon(Icons.shopping_basket_outlined),
                        label: Text(AppTranslation.addToCart),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

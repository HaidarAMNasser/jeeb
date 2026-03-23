import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/merchant/merchant_details/presentation/bloc/merchant_details_bloc.dart';
import 'package:jeeb_app/features/merchant/merchant_details/presentation/widgets/merchant_details_content.dart';
import 'package:jeeb_app/features/offer/list_offer/presentation/bloc/list_offer_bloc.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';

class MerchantDetailsPage extends StatefulWidget {
  final String merchantId;

  const MerchantDetailsPage({super.key, required this.merchantId});

  @override
  State<MerchantDetailsPage> createState() => _MerchantDetailsPageState();
}

class _MerchantDetailsPageState extends State<MerchantDetailsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load merchant details
    context.read<MerchantDetailsBloc>().add(
      GetMerchantDetailsEvent(id: widget.merchantId),
    );
    // Load products for this merchant (preview: first page only, section shows 3 + "Show all")
    context.read<ListProductBloc>().add(
      GetProductsEvent(merchantId: widget.merchantId),
    );
    // Load offers for this merchant (preview: first page only, section shows 3 + "Show all")
    context.read<ListOfferBloc>().add(
      GetOffersEvent(merchantId: widget.merchantId),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.merchantDetails),
      body: Builder(
        builder: (context) {
          return BlocStateHandler<MerchantDetailsBloc, MerchantDetailsState>(
            bloc: context.read<MerchantDetailsBloc>(),
            isLoading: (state) => state is MerchantDetailsLoading,
            isError: (state) => state is MerchantDetailsError,
            getErrorMessage: (state) => (state as MerchantDetailsError).message,
            isSuccess: (state) => state is MerchantDetailsLoaded,
            getRetryCallback: (state) => () {
              context.read<MerchantDetailsBloc>().add(
                GetMerchantDetailsEvent(id: widget.merchantId),
              );
            },
            successBuilder: (context, detailsState) {
              final loadedState = detailsState as MerchantDetailsLoaded;
              return MerchantDetailsContent(
                merchant: loadedState.merchant,
                merchantId: widget.merchantId,
                scrollController: _scrollController,
              );
            },
          );
        },
      ),
    );
  }
}

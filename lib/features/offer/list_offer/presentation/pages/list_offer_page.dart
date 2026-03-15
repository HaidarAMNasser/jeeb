import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:jeeb_app/features/offer/list_offer/presentation/bloc/list_offer_bloc.dart';
import 'package:jeeb_app/features/offer/list_offer/presentation/widgets/offer_list_item.dart';

class ListOfferPage extends StatefulWidget {
  const ListOfferPage({super.key});

  @override
  State<ListOfferPage> createState() => _ListOfferPageState();
}

class _ListOfferPageState extends State<ListOfferPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial load is triggered by route when bloc is created
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<ListOfferBloc>().state;
    if (state is ListOfferLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (state is ListOfferLoaded && state.hasMore) {
        context.read<ListOfferBloc>().add(GetOffersEvent(loadMore: true, merchantId: state.merchantId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.offers),
      body: BlocBuilder<ListOfferBloc, ListOfferState>(
        builder: (context, state) {
          return BlocStateHandler<ListOfferBloc, ListOfferState>(
            bloc: context.read<ListOfferBloc>(),
            isLoading: (s) => s is ListOfferLoading,
            isError: (s) => s is ListOfferError,
            getErrorMessage: (s) => (s as ListOfferError).message,
            isSuccess: (s) =>
                s is ListOfferLoaded || s is ListOfferLoadingMore,
            isEmpty: (s) {
              if (s is ListOfferLoaded) return s.offers.isEmpty;
              if (s is ListOfferLoadingMore) return s.offers.isEmpty;
              return false;
            },
            emptyMessage: AppTranslation.noOffersFound,
            getRetryCallback: (_) => () {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final merchantId = args?['merchantId'] as String?;
              context.read<ListOfferBloc>().add(GetOffersEvent(merchantId: merchantId));
            },
            successBuilder: (context, offerState) {
              final offers = offerState is ListOfferLoaded
                  ? offerState.offers
                  : (offerState as ListOfferLoadingMore).offers;
              final hasMore = offerState is ListOfferLoaded
                  ? offerState.hasMore
                  : false;

              return RefreshIndicator(
                onRefresh: () async {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  final merchantId = args?['merchantId'] as String?;
                  context.read<ListOfferBloc>().add(GetOffersEvent(merchantId: merchantId));
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(AppPadding.p16),
                  itemCount: offers.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == offers.length) {
                      return Padding(
                        padding: EdgeInsets.all(AppPadding.p16),
                        child: const CustomCircleIndicator(),
                      );
                    }
                    return OfferListItem(offer: offers[index]);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<String?>(
        future: di.sl<StorageService>().getUserRole(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data?.toLowerCase() == UserRole.admin.name;
          if (isAdmin) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: ColorManager.primary,
            onPressed: () {
              Navigator.pushNamed(context, Routes.addOffer);
            },
            child: Icon(Icons.add, color: ColorManager.surface),
          );
        },
      ),
    );
  }
}

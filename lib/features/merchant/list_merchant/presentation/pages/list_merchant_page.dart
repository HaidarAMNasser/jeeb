import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/bloc/list_merchant_bloc.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/widgets/merchant_list_item.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/widgets/search_merchant_widget.dart';

class ListMerchantPage extends StatefulWidget {
  const ListMerchantPage({super.key});

  @override
  State<ListMerchantPage> createState() => _ListMerchantPageState();
}

class _ListMerchantPageState extends State<ListMerchantPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial merchants
    context.read<ListMerchantBloc>().add(const GetMerchantsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<ListMerchantBloc>().state;
    // Prevent loading more if already loading
    if (state is ListMerchantLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (state is ListMerchantLoaded && state.hasMore) {
        // Use the search query from state when loading more
        context.read<ListMerchantBloc>().add(
          GetMerchantsEvent(loadMore: true, search: state.search),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.merchants),
      body: Column(
        children: [
          const SearchMerchantWidget(),
          Expanded(
            child: BlocStateHandler<ListMerchantBloc, ListMerchantState>(
              bloc: context.read<ListMerchantBloc>(),
              isLoading: (state) => state is ListMerchantLoading,
              isError: (state) => state is ListMerchantError,
              getErrorMessage: (state) => (state as ListMerchantError).message,
              isSuccess: (state) =>
                  state is ListMerchantLoaded ||
                  state is ListMerchantLoadingMore,
              isEmpty: (state) {
                if (state is ListMerchantLoaded) return state.merchants.isEmpty;
                if (state is ListMerchantLoadingMore) {
                  return state.merchants.isEmpty;
                }
                return false;
              },
              emptyMessage: AppTranslation.noMerchantsFound,
              getRetryCallback: (_) => () {
                context.read<ListMerchantBloc>().add(const GetMerchantsEvent());
              },
              successBuilder: (context, merchantState) {
                final merchants = merchantState is ListMerchantLoaded
                    ? merchantState.merchants
                    : (merchantState as ListMerchantLoadingMore).merchants;
                final hasMore = merchantState is ListMerchantLoaded
                    ? merchantState.hasMore
                    : false;
                final currentSearch = merchantState is ListMerchantLoaded
                    ? merchantState.search
                    : (merchantState as ListMerchantLoadingMore).search;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<ListMerchantBloc>().add(
                          GetMerchantsEvent(search: currentSearch),
                        );
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                    itemCount: merchants.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == merchants.length) {
                        return Padding(
                          padding: EdgeInsets.all(AppPadding.p16),
                          child: const CustomCircleIndicator(),
                        );
                      }
                      return MerchantListItem(merchant: merchants[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

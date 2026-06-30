import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/widgets/list_order_content.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/widgets/search_order_widget.dart';

class ListOrderPage extends StatefulWidget {
  final bool? removeBack;
  const ListOrderPage({super.key, this.removeBack});

  @override
  State<ListOrderPage> createState() => _ListOrderPageState();
}

class _ListOrderPageState extends State<ListOrderPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<ListOrderBloc>().state;
    if (state is ListOrderLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (state is ListOrderLoaded && state.hasMore) {
        context.read<ListOrderBloc>().add(
          GetOrdersEvent(
            loadMore: true,
            search: state.search,
            merchantId: state.merchantId,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ListOrderBloc>();

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(
        title: AppTranslation.orders,
        automaticallyImplyLeading:
            (widget.removeBack != null && widget.removeBack!) ? false : true,
      ),
      body: Column(
        children: [
          const SearchOrderWidget(),
          Expanded(
            child: BlocStateHandler<ListOrderBloc, ListOrderState>(
              bloc: bloc,
              isLoading: (state) => state is ListOrderLoading,
              isError: (state) => state is ListOrderError,
              getErrorMessage: (state) => (state as ListOrderError).message,
              isSuccess: (state) =>
                  state is ListOrderLoaded || state is ListOrderLoadingMore,
              isEmpty: (state) {
                if (state is ListOrderLoaded) return state.orders.isEmpty;
                if (state is ListOrderLoadingMore) return state.orders.isEmpty;
                return false;
              },
              emptyMessage: AppTranslation.noOrdersFound,
              getRetryCallback: (_) => () {
                bloc.add(const GetOrdersEvent());
              },
              successBuilder: (context, orderState) {
                String? currentSearch;
                if (orderState is ListOrderLoaded) {
                  currentSearch = orderState.search;
                } else if (orderState is ListOrderLoadingMore) {
                  currentSearch = orderState.search;
                }

                final orders = orderState is ListOrderLoaded
                    ? orderState.orders
                    : (orderState as ListOrderLoadingMore).orders;
                final hasMore = orderState is ListOrderLoaded
                    ? orderState.hasMore
                    : true;

                return ListOrderContent(
                  orders: orders,
                  hasMore: hasMore,
                  scrollController: _scrollController,
                  onRefresh: () async {
                    bloc.add(GetOrdersEvent(search: currentSearch));
                  },
                  currentSearch: currentSearch,
                  merchantId: orderState is ListOrderLoaded
                      ? orderState.merchantId
                      : (orderState as ListOrderLoadingMore).merchantId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

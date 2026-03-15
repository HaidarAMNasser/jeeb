import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/order/list_order/presentation/widgets/order_list_item.dart';
import 'package:jeeb_app/features/order/list_order/presentation/widgets/search_order_widget.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';

class OrderHeaderCard extends StatelessWidget {
  final OrderEntity order;

  const OrderHeaderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.defaultWhite,
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: '${AppTranslation.order} #${order.id}',
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.productNameColor,
              ),
            ),
            if (order.status != null) ...[
              SizedBox(height: AppHeight.s8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.p8,
                  vertical: AppPadding.p4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: CustomText(
                  text: order.status!,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s12,
                    color: _getStatusColor(order.status!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return ColorManager.primary;
    }
  }
}


class ListOrderPage extends StatefulWidget {
  const ListOrderPage({super.key});

  @override
  State<ListOrderPage> createState() => _ListOrderPageState();
}

class _ListOrderPageState extends State<ListOrderPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial orders
    // context.read<ListOrderBloc>().add(
    //   GetOrdersEvent(merchantId: _merchantId),
    // );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<ListOrderBloc>().state;
    // Prevent loading more if already loading
    if (state is ListOrderLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (state is ListOrderLoaded && state.hasMore) {
        // Use the search query and merchantId from state when loading more
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
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.orders),

      body: BlocBuilder<ListOrderBloc, ListOrderState>(
        builder: (context, state) {
          // Get current search query from state for refresh
          String? currentSearch;
          if (state is ListOrderLoaded) {
            currentSearch = state.search;
          } else if (state is ListOrderLoadingMore) {
            currentSearch = state.search;
          }

          // return BlocStateHandler<ListOrderBloc, ListOrderState>(
          //   bloc: context.read<ListOrderBloc>(),
          //   isLoading: (state) => state is ListOrderLoading,
          //   isError: (state) => state is ListOrderError,
          //   getErrorMessage: (state) => (state as ListOrderError).message,
          //   isSuccess: (state) =>
          //       state is ListOrderLoaded || state is ListOrderLoadingMore,
          //   isEmpty: (state) {
          //     if (state is ListOrderLoaded) {
          //       return state.orders.isEmpty;
          //     }
          //     if (state is ListOrderLoadingMore) {
          //       return state.orders.isEmpty;
          //     }
          //     return false;
          //   },
          //   emptyMessage: AppTranslation.noOrdersFound,
          //   getRetryCallback: (state) => () {
          //     context.read<ListOrderBloc>().add(
          //           GetOrdersEvent(merchantId: merchantId),
          //         );
          //   },
          //   successBuilder: (context, orderState) {
          //     final orders = orderState is ListOrderLoaded
          //         ? orderState.orders
          //         : (orderState as ListOrderLoadingMore).orders;
          //     final hasMore = orderState is ListOrderLoaded
          //         ? orderState.hasMore
          //         : false;

          //     return ListOrderContent(
          //       orders: orders,
          //       hasMore: hasMore,
          //       scrollController: _scrollController,
          //       onRefresh: () {
          //         context.read<ListOrderBloc>().add(
          //           GetOrdersEvent(
          //             search: currentSearch,
          //             merchantId: merchantId,
          //           ),
          //         );
          //       },
          //       currentSearch: currentSearch,
          //       merchantId: merchantId,
          //     );
          //   },
          // );

          // Fake data ListView for UI testing with search
          final fakeOrders = _generateFakeOrders();
          final searchQuery = currentSearch?.toLowerCase() ?? '';
          final filteredOrders = searchQuery.isEmpty
              ? fakeOrders
              : fakeOrders.where((order) {
                  final status = order.status?.toLowerCase() ?? '';
                  return order.id.toLowerCase().contains(searchQuery) ||
                      status.contains(searchQuery);
                }).toList();

          return Column(
            children: [
              // Search field
              const SearchOrderWidget(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<ListOrderBloc>().add(
                      GetOrdersEvent(search: currentSearch),
                    );
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return OrderListItem(order: order);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Fake data generation for UI testing
  List<OrderEntity> _generateFakeOrders() {
    return List.generate(25, (index) {
      return OrderEntity(
        id: '${index + 1}',
        products: _generateFakeProductsForOrder(index),
        date: DateTime.now().subtract(Duration(days: index)),
        longitude: 35.5018 + (index * 0.01),
        latitude: 33.8938 + (index * 0.01),
        numberOfPeople: 2 + (index % 5),
        status: [OrderStatus.pending, OrderStatus.completed, OrderStatus.cancelled][index % 3].name,
        merchantId: 'merchant_${(index % 5) + 1}',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(hours: index)),
      );
    });
  }

  List<ProductEntity> _generateFakeProductsForOrder(int orderIndex) {
    final productNames = ['Burger', 'Pizza', 'Pasta', 'Salad', 'Sandwich'];
    return List.generate(2 + (orderIndex % 3), (productIndex) {
      return ProductEntity(
        id: 'product_${orderIndex}_$productIndex',
        name: productNames[productIndex % productNames.length],
        description:
            'Delicious ${productNames[productIndex % productNames.length]}',
        price: 1000 + (productIndex * 500),
        categoryId: 'cat1',
        categoryName: 'Fast Food',
        images: [
          ProductImageEntity(
            id: productIndex + 1,
            url:
                'https://picsum.photos/seed/product${orderIndex}_$productIndex/200/200',
            mobileUrl:
                'https://picsum.photos/seed/product${orderIndex}_$productIndex/200/200',
            thumbnailUrl:
                'https://picsum.photos/seed/product${orderIndex}_$productIndex/200/200',
            isMain: true,
            displayOrder: 1,
          ),
        ],
      );
    });
  }
}

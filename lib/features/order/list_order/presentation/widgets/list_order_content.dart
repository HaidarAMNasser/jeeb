import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/order/list_order/presentation/widgets/order_list_item.dart';
import 'package:jeeb_app/features/order/list_order/presentation/widgets/search_order_widget.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';

class ListOrderContent extends StatelessWidget {
  final List<OrderEntity> orders;
  final bool hasMore;
  final ScrollController scrollController;
  final VoidCallback onRefresh;
  final String? currentSearch;
  final String? merchantId;

  const ListOrderContent({
    super.key,
    required this.orders,
    required this.hasMore,
    required this.scrollController,
    required this.onRefresh,
    this.currentSearch,
    this.merchantId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        const SearchOrderWidget(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p16,
              ),
              itemCount: orders.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == orders.length) {
                  return Padding(
                    padding: EdgeInsets.all(AppPadding.p16),
                    child: const CustomCircleIndicator(),
                  );
                }
                final order = orders[index];
                return OrderListItem(order: order);
              },
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/features/delivery/home/presentation/widgets/delivery_order_card.dart';
import 'package:jeeb_app/features/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';

class DeliveryOrdersPage extends StatelessWidget {
  const DeliveryOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ListOrderBloc>()..add(const GetOrdersEvent()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: ColorManager.background,
          appBar: AppBar(
            backgroundColor: ColorManager.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              AppTranslation.myOrders,
              style: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.titlesColor,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                decoration: BoxDecoration(
                  color: ColorManager.primaryDark,
                  borderRadius: BorderRadius.circular(AppSize.s12),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: ColorManager.textSecondary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: BorderRadius.circular(AppSize.s10),
                  ),
                  labelStyle: getSemiBoldStyle(fontSize: AppFontSize.s14),
                  unselectedLabelStyle: getRegularStyle(
                    fontSize: AppFontSize.s14,
                  ),
                  tabs: [
                    Tab(text: AppTranslation.pending),
                    Tab(text: AppTranslation.completed),
                    Tab(text: AppTranslation.cancelled),
                  ],
                ),
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              _OrdersTabContent(type: _OrderTabType.pending),
              _OrdersTabContent(type: _OrderTabType.completed),
              _OrdersTabContent(type: _OrderTabType.cancelled),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OrderTabType { pending, completed, cancelled }

class _OrdersTabContent extends StatefulWidget {
  final _OrderTabType type;

  const _OrdersTabContent({required this.type});

  @override
  State<_OrdersTabContent> createState() => _OrdersTabContentState();
}

class _OrdersTabContentState extends State<_OrdersTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ListOrderBloc, ListOrderState>(
      builder: (context, state) {
        return BlocStateHandler<ListOrderBloc, ListOrderState>(
          bloc: context.read<ListOrderBloc>(),
          isLoading: (s) => s is ListOrderLoading,
          loadingWidget: const Center(child: CustomCircleIndicator()),
          isError: (s) => s is ListOrderError,
          getErrorMessage: (s) => (s as ListOrderError).message,
          errorBuilder: (context, message, onRetry) =>
              ErrorStateWidget(message: message, onRetry: onRetry),
          isSuccess: (s) => s is ListOrderLoaded,
          isEmpty: (s) {
            if (s is! ListOrderLoaded) return false;
            final filtered = _filterOrders(s.orders);
            return filtered.isEmpty;
          },
          emptyBuilder: (context) => _buildEmptyState(),
          getRetryCallback: (_) =>
              () => context.read<ListOrderBloc>().add(const GetOrdersEvent()),
          successBuilder: (context, s) {
            final loadedState = s as ListOrderLoaded;
            final filteredOrders = _filterOrders(loadedState.orders);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ListOrderBloc>().add(const GetOrdersEvent());
              },
              color: ColorManager.primary,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: AppPadding.p16),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(bottom: AppPadding.p16),
                  child: DeliveryOrderCard(
                    order: filteredOrders[index],
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.deliveryOrderDetails,
                        arguments: {'orderId': filteredOrders[index].id},
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<OrderEntity> _filterOrders(List<OrderEntity> orders) {
    switch (widget.type) {
      case _OrderTabType.pending:
        return orders.where((o) {
          final status = OrderStatus.fromString(o.status);
          return status != OrderStatus.completed &&
              status != OrderStatus.delivered &&
              status != OrderStatus.cancelled;
        }).toList();
      case _OrderTabType.completed:
        return orders.where((o) {
          final status = OrderStatus.fromString(o.status);
          return status == OrderStatus.completed ||
              status == OrderStatus.delivered;
        }).toList();
      case _OrderTabType.cancelled:
        return orders.where((o) {
          final status = OrderStatus.fromString(o.status);
          return status == OrderStatus.cancelled;
        }).toList();
    }
  }

  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.list_alt_outlined;

    switch (widget.type) {
      case _OrderTabType.pending:
        message = 'No pending orders found.';
        icon = Icons.hourglass_empty_rounded;
        break;
      case _OrderTabType.completed:
        message = 'No completed orders found.';
        icon = Icons.check_circle_outline_rounded;
        break;
      case _OrderTabType.cancelled:
        message = 'No cancelled orders found.';
        icon = Icons.cancel_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppSize.s70,
            color: ColorManager.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: AppHeight.s16),
          Text(
            message,
            style: getMediumStyle(
              fontSize: AppFontSize.s16,
              color: ColorManager.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

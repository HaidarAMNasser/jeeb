import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'delivery_orders_empty_state.dart';
import 'delivery_orders_list.dart';

/// Delivery "My Orders" list body driven by an explicit status filter.
class DeliveryOrdersTabContent extends StatelessWidget {
  const DeliveryOrdersTabContent({
    super.key,
    required this.status,
    this.emptyMessage,
    this.refreshOnManageOrderSuccess = false,
  });

  /// Optional comma-separated `OrderStatus.apiWireValue` list.
  /// Null means "show all" (do not send status query).
  final String? status;
  final String? emptyMessage;
  final bool refreshOnManageOrderSuccess;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ListOrderBloc>(),
      child: _DeliveryOrdersContentBody(
        status: status,
        emptyMessage: emptyMessage,
        refreshOnManageOrderSuccess: refreshOnManageOrderSuccess,
      ),
    );
  }
}

class _DeliveryOrdersContentBody extends StatefulWidget {
  const _DeliveryOrdersContentBody({
    required this.status,
    this.emptyMessage,
    required this.refreshOnManageOrderSuccess,
  });

  final String? status;
  final String? emptyMessage;
  final bool refreshOnManageOrderSuccess;

  @override
  State<_DeliveryOrdersContentBody> createState() =>
      _DeliveryOrdersContentBodyState();
}

class _DeliveryOrdersContentBodyState extends State<_DeliveryOrdersContentBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant _DeliveryOrdersContentBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    context.read<ListOrderBloc>().add(GetOrdersEvent(status: widget.status));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<ManageOrderBloc, ManageOrderState>(
      listenWhen: (_, cur) =>
          widget.refreshOnManageOrderSuccess && cur is ManageOrderSuccess,
      listener: (_, __) => _loadOrders(),
      child: BlocBuilder<ListOrderBloc, ListOrderState>(
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
            isEmpty: (s) => s is ListOrderLoaded && s.orders.isEmpty,
            emptyBuilder: (context) => _buildEmptyState(),
            getRetryCallback: (_) => _loadOrders,
            successBuilder: (context, s) {
              final loadedState = s as ListOrderLoaded;
              final list = List<OrderEntity>.from(loadedState.orders);
              // Put SEARCHING first when present.
              list.sort((a, b) {
                final sa = OrderStatus.fromString(a.status);
                final sb = OrderStatus.fromString(b.status);
                if (sa == OrderStatus.searching && sb != OrderStatus.searching) {
                  return -1;
                }
                if (sb == OrderStatus.searching && sa != OrderStatus.searching) {
                  return 1;
                }
                return 0;
              });
              return DeliveryOrdersList(
                orders: list,
                status: widget.status,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return DeliveryOrdersEmptyState(
      message: widget.emptyMessage ?? AppTranslation.noAssignedOrders,
      icon: Icons.list_alt_outlined,
    );
  }
}

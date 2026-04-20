import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_pay_selection_controller.dart';
import 'delivery_orders_list.dart';
import 'delivery_orders_empty_state.dart';

enum DeliveryOrderTabType { pending, completed, cancelled }

class DeliveryOrdersTabContent extends StatelessWidget {
  final DeliveryOrderTabType type;

  const DeliveryOrdersTabContent({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<ListOrderBloc>(),
      child: _DeliveryOrdersTabContentBody(type: type),
    );
  }
}

class _DeliveryOrdersTabContentBody extends StatefulWidget {
  final DeliveryOrderTabType type;

  const _DeliveryOrdersTabContentBody({required this.type});

  @override
  State<_DeliveryOrdersTabContentBody> createState() =>
      _DeliveryOrdersTabContentBodyState();
}

class _DeliveryOrdersTabContentBodyState
    extends State<_DeliveryOrdersTabContentBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String get _status {
    switch (widget.type) {
      case DeliveryOrderTabType.pending:
        return [
          OrderStatus.preparing.apiWireValue,
          OrderStatus.readyForPickup.apiWireValue,
          OrderStatus.assigned.apiWireValue,
          OrderStatus.pickedUp.apiWireValue,
          OrderStatus.onTheWay.apiWireValue,
        ].join(',');
      case DeliveryOrderTabType.completed:
        return [
          OrderStatus.delivered,
          OrderStatus.paid,
          OrderStatus.completed,
        ].map((s) => s.apiWireValue).join(',');
      case DeliveryOrderTabType.cancelled:
        return OrderStatus.cancelled.apiWireValue;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.type == DeliveryOrderTabType.completed) {
      di.sl<DeliveryPaySelectionController>().completedTabReloadTick.addListener(
            _onCompletedReloadTick,
          );
    }
    _loadOrders();
  }

  @override
  void dispose() {
    if (widget.type == DeliveryOrderTabType.completed) {
      di.sl<DeliveryPaySelectionController>().completedTabReloadTick.removeListener(
            _onCompletedReloadTick,
          );
    }
    super.dispose();
  }

  void _onCompletedReloadTick() {
    _loadOrders();
  }

  void _loadOrders() {
    context.read<ListOrderBloc>().add(GetOrdersEvent(status: _status));
  }

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
          isSuccess: (s) => s is ListOrderLoaded && s.status == _status,
          isEmpty: (s) =>
              s is ListOrderLoaded && s.status == _status && s.orders.isEmpty,
          emptyBuilder: (context) => _buildEmptyState(),
          getRetryCallback: (_) => _loadOrders,
          successBuilder: (context, s) {
            final loadedState = s as ListOrderLoaded;
            if (widget.type == DeliveryOrderTabType.completed) {
              di.sl<DeliveryPaySelectionController>().onCompletedOrdersLoaded(
                loadedState.orders,
              );
            }
            return DeliveryOrdersList(
              orders: loadedState.orders,
              status: _status,
              tabType: widget.type,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.list_alt_outlined;

    switch (widget.type) {
      case DeliveryOrderTabType.pending:
        message = AppTranslation.noAssignedOrders;
        icon = Icons.delivery_dining_rounded;
        break;
      case DeliveryOrderTabType.completed:
        message = AppTranslation.noCompletedOrders;
        icon = Icons.check_circle_outline_rounded;
        break;
      case DeliveryOrderTabType.cancelled:
        message = AppTranslation.noCancelledOrders;
        icon = Icons.cancel_outlined;
        break;
    }

    return DeliveryOrdersEmptyState(message: message, icon: icon);
  }
}

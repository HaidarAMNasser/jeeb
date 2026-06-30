import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_orders/widgets/delivery_orders_tab_content.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_pay_selection_controller.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/pay_admin/presentation/bloc/pay_admin_bloc.dart';
import 'package:jeeb_app/features/delivery/pay_admin/presentation/widgets/delivery_pay_admin_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryOrdersPage extends StatefulWidget {
  final bool? removeBack;
  const DeliveryOrdersPage({super.key,this.removeBack});

  @override
  State<DeliveryOrdersPage> createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends State<DeliveryOrdersPage> {
  static const String _allFilterValue = 'ALL';
  String _selectedFilterValue = _allFilterValue;

  static const List<OrderStatus> _myOrdersStatuses = [
    OrderStatus.searching,
    OrderStatus.assigned,
    OrderStatus.preparing,
    OrderStatus.readyForPickup,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
    OrderStatus.cancelled,
    OrderStatus.rejected,
    OrderStatus.completed,
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get _statusParam {
    if (_selectedFilterValue == _allFilterValue) {
      // Show all => same endpoint without `status` query param.
      return null;
    }
    return _selectedFilterValue;
  }

  String get _emptyMessage {
    if (_selectedFilterValue == _allFilterValue) {
      return AppTranslation.noOrdersFound;
    }
    final s = OrderStatus.fromString(_selectedFilterValue);
    if (s == OrderStatus.cancelled || s == OrderStatus.rejected) {
      return AppTranslation.noCancelledOrders;
    }
    if (s == OrderStatus.delivered || s == OrderStatus.paid || s == OrderStatus.completed) {
      return AppTranslation.noCompletedOrders;
    }
    return AppTranslation.noAssignedOrders;
  }

  Color _filterTextColor(OrderStatus? status) {
    if (status == null) return const Color(0xFFEAD9CE);
    switch (status) {
      case OrderStatus.searching:
        return const Color(0xFFFFC857);
      case OrderStatus.assigned:
      case OrderStatus.preparing:
      case OrderStatus.readyForPickup:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return const Color(0xFFFF9E5E);
      case OrderStatus.delivered:
      case OrderStatus.paid:
      case OrderStatus.completed:
        return const Color(0xFF6ED99F);
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return const Color(0xFFFF7B7B);
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.unknown:
        return ColorManager.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: (widget.removeBack != null && widget.removeBack!) ? false : true,
        title: Text(
          AppTranslation.myOrders,
          style: getBoldStyle(
            fontSize: AppFontSize.s20,
            color: ColorManager.titlesColor,
          ),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable:
                di.sl<DeliveryPaySelectionController>().batchMode,
            builder: (context, batch, _) {
              final showBatchPay =
                  batch && _selectedFilterValue == OrderStatus.delivered.apiWireValue;
              if (!showBatchPay) {
                return const SizedBox.shrink();
              }
              return ValueListenableBuilder<Set<String>>(
                valueListenable: di
                    .sl<DeliveryPaySelectionController>()
                    .selectedOrderIds,
                builder: (context, ids, __) {
                  return TextButton(
                    onPressed: ids.isEmpty ? null : () => _openBatchPay(context, ids),
                    child: Text(AppTranslation.payAppBarPay),
                  );
                },
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded, color: ColorManager.defaultWhite),
            color: ColorManager.primaryDark,
            onSelected: (v) => setState(() => _selectedFilterValue = v),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: _allFilterValue,
                child: Text(
                  AppTranslation.showAll,
                  style: getSemiBoldStyle(
                    fontSize: AppFontSize.s14,
                    color: _filterTextColor(null),
                  ),
                ),
              ),
              ..._myOrdersStatuses.map(
                (s) => PopupMenuItem<String>(
                  value: s.apiWireValue,
                  child: Text(
                    s.displayLabel,
                    style: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: _filterTextColor(s),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: DeliveryOrdersTabContent(
        status: _statusParam,
        emptyMessage: _emptyMessage,
        refreshOnManageOrderSuccess: true,
      ),
    );
  }

  void _openBatchPay(BuildContext context, Set<String> ids) {
    final snapshot = di.sl<DeliveryPaySelectionController>().lastCompletedOrders.value;
    final orders = snapshot
        .where((o) => ids.contains(o.id))
        .where(
          (o) => OrderStatus.fromString(o.status) == OrderStatus.delivered,
        )
        .toList();
    if (orders.isEmpty) return;
    PayAdminBloc? b;
    try {
      b = context.read<PayAdminBloc>();
    } catch (_) {
      b = null;
    }
    showPayAdminReceiptDialog(
      context,
      bloc: b,
      orderIds: orders.map((e) => e.id).toList(),
      ordersForTotals: orders,
      onSuccess: () {
        di.sl<DeliveryPaySelectionController>().clear();
        di.sl<DeliveryPaySelectionController>().completedTabReloadTick.value++;
      },
    );
  }
}

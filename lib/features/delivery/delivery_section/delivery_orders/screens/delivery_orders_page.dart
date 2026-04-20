import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_orders/widgets/delivery_orders_tab_content.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_orders_inner_tab.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_pay_selection_controller.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/pay_admin/presentation/bloc/pay_admin_bloc.dart';
import 'package:jeeb_app/features/delivery/pay_admin/presentation/widgets/delivery_pay_admin_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeliveryOrdersPage extends StatefulWidget {
  const DeliveryOrdersPage({super.key});

  @override
  State<DeliveryOrdersPage> createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends State<DeliveryOrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    DeliveryOrdersInnerTab.tabIndex.addListener(_onJumpToInnerTab);
    _tabController.addListener(_syncInnerTabNotifier);
  }

  void _syncInnerTabNotifier() {
    if (!_tabController.indexIsChanging) {
      DeliveryOrdersInnerTab.tabIndex.value = _tabController.index;
    }
  }

  void _onJumpToInnerTab() {
    final v = DeliveryOrdersInnerTab.tabIndex.value;
    if (v >= 0 && v < _tabController.length && v != _tabController.index) {
      _tabController.animateTo(v);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DeliveryOrdersInnerTab.tabIndex.removeListener(_onJumpToInnerTab);
    _tabController.removeListener(_syncInnerTabNotifier);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable:
                di.sl<DeliveryPaySelectionController>().batchMode,
            builder: (context, batch, _) {
              if (_tabController.index != 1 || !batch) {
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: AppPadding.p16),
            decoration: BoxDecoration(
              color: ColorManager.primaryDark,
              borderRadius: BorderRadius.circular(AppSize.s12),
            ),
            child: TabBar(
              controller: _tabController,
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
              onTap: (i) => DeliveryOrdersInnerTab.tabIndex.value = i,
              tabs: [
                Tab(text: AppTranslation.pending),
                Tab(text: AppTranslation.completed),
                Tab(text: AppTranslation.cancelled),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DeliveryOrdersTabContent(type: DeliveryOrderTabType.pending),
          DeliveryOrdersTabContent(type: DeliveryOrderTabType.completed),
          DeliveryOrdersTabContent(type: DeliveryOrderTabType.cancelled),
        ],
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

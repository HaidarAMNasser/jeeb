import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_navigation_tabs.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_orders_inner_tab.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_pay_selection_controller.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/widgets/delivery_payment_receipt_picker.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/pay_admin/presentation/bloc/pay_admin_bloc.dart';

Future<void> showPayAdminReceiptDialog(
  BuildContext context, {
  PayAdminBloc? bloc,
  required List<String> orderIds,
  required List<OrderEntity> ordersForTotals,
  VoidCallback? onSuccess,
}) async {
  final imagePaths = await DeliveryPaymentReceiptPicker.show(context);
  if (imagePaths == null || imagePaths.isEmpty) return;

  final effectiveBloc = bloc ?? di.sl<PayAdminBloc>();
  // Clear any previous success/failure so we only react to this submission.
  effectiveBloc.add(const PayAdminReset());
  effectiveBloc.add(
    PayAdminSubmit(
      orderIds: orderIds,
      // API still expects one image path for this endpoint.
      receiptImagePath: imagePaths.first,
    ),
  );

  final result = await effectiveBloc.stream.firstWhere(
    (s) => s is PayAdminSuccess || s is PayAdminFailureState,
  );
  if (!context.mounted) return;

  if (result is PayAdminSuccess) {
    customToast(msg: AppTranslation.payAdminSuccess);
    onSuccess?.call();
    effectiveBloc.add(const PayAdminReset());
    return;
  }

  if (result is PayAdminFailureState) {
    customToast(
      msg: '${AppTranslation.payAdminFailure}: ${result.message}',
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
    );
  }
}

enum DeliveryPayAdminEntryKind { orderList, orderDetails }

/// Three-dot entry: pay now (single order) or batch selection (completed tab).
class DeliveryPayAdminMenuButton extends StatelessWidget {
  const DeliveryPayAdminMenuButton({
    super.key,
    required this.order,
    required this.pageOrders,
    this.entryKind = DeliveryPayAdminEntryKind.orderList,
    this.payAdminBloc,
    this.onAfterPaySuccess,
  });

  final OrderEntity order;
  final List<OrderEntity> pageOrders;
  final DeliveryPayAdminEntryKind entryKind;
  final PayAdminBloc? payAdminBloc;
  final VoidCallback? onAfterPaySuccess;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: ColorManager.titlesColor),
      onSelected: (value) {
        final controller = di.sl<DeliveryPaySelectionController>();
        if (value == 'pay') {
          showPayAdminReceiptDialog(
            context,
            bloc: payAdminBloc,
            orderIds: [order.id],
            ordersForTotals: [order],
            onSuccess: onAfterPaySuccess,
          );
        } else if (value == 'list') {
          if (entryKind == DeliveryPayAdminEntryKind.orderDetails) {
            controller.requestSelectAllDeliveredAfterListLoads();
            DeliveryNavigationTabs.goToOrdersTab();
            DeliveryOrdersInnerTab.goToCompleted();
            Navigator.of(context).maybePop();
          } else {
            final delivered = pageOrders
                .where((o) => (o.status ?? '').toUpperCase() == 'DELIVERED')
                .map((o) => o.id)
                .toSet();
            controller.enterBatchModeWithDeliveredIds(delivered);
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pay',
          child: Text(AppTranslation.payAdminOptionPayNow),
        ),
        PopupMenuItem(
          value: 'list',
          child: Text(AppTranslation.payAdminOptionAddToList),
        ),
      ],
    );
  }
}

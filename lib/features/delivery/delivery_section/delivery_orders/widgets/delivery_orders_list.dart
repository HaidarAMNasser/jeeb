import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/common/classes/user_roles.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/pages/delivery_home_page_actions.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_card.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/searching%20cards/delivery_searching_order_card.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_pay_selection_controller.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class DeliveryOrdersList extends StatelessWidget {
  final List<OrderEntity> orders;
  final String? status;

  const DeliveryOrdersList({
    super.key,
    required this.orders,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isDeliveryDriver(di.sl<StorageService>()),
      builder: (context, snap) {
        final isDriver = snap.data ?? false;
        return RefreshIndicator(
          onRefresh: () async {
            context.read<ListOrderBloc>().add(GetOrdersEvent(status: status));
          },
          color: ColorManager.primary,
          child: ValueListenableBuilder<bool>(
            valueListenable: di.sl<DeliveryPaySelectionController>().batchMode,
            builder: (context, batch, _) {
              return ValueListenableBuilder<Set<String>>(
                valueListenable:
                    di.sl<DeliveryPaySelectionController>().selectedOrderIds,
                builder: (context, selected, __) {
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: AppPadding.p16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final o = orders[index];
                      final st = OrderStatus.fromString(o.status);
                      final canBatch =
                          batch && st == OrderStatus.delivered;

                      Future<void> openDetails() async {
                        await Navigator.pushNamed<void>(
                          context,
                          Routes.deliveryOrderDetails,
                          arguments: {'orderId': o.id},
                        );
                        if (!context.mounted) return;
                        context.read<ListOrderBloc>().add(
                              GetOrdersEvent(status: status),
                            );
                      }

                      if (isDriver && st == OrderStatus.searching) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppPadding.p16),
                          child: DeliverySearchingOrderCard(
                            order: o,
                            onAccept: () =>
                                deliveryHomeConfirmAcceptOrder(context, o),
                            onTap: openDetails,
                            onTimerExpired: null,
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(bottom: AppPadding.p16),
                        child: DeliveryOrderCard(
                          order: o,
                          pageOrders: orders,
                          isDeliveryDriver: isDriver,
                          batchPaySelection: canBatch,
                          selectedForAdminPay: selected.contains(o.id),
                          onAdminPaySelectionToggle: canBatch
                              ? () => di
                                  .sl<DeliveryPaySelectionController>()
                                  .toggleOrderId(o.id)
                              : null,
                          onPayAdminSuccess: () {
                            context.read<ListOrderBloc>().add(
                                  GetOrdersEvent(status: status),
                                );
                          },
                          onTap: openDetails,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

Future<bool> _isDeliveryDriver(StorageService storage) async {
  final r = await storage.getUserRole();
  if (r == null || r.isEmpty) return false;
  final u = r.toUpperCase();
  return u == 'DELIVERY' || r == UserRoles.deliveryMan.name;
}

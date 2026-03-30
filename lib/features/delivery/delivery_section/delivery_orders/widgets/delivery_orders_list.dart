import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_card.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class DeliveryOrdersList extends StatelessWidget {
  final List<OrderEntity> orders;
  final String? status;

  const DeliveryOrdersList({super.key, required this.orders, this.status});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ListOrderBloc>().add(GetOrdersEvent(status: status));
      },
      color: ColorManager.primary,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: AppPadding.p16),
        itemCount: orders.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(bottom: AppPadding.p16),
          child: DeliveryOrderCard(
            order: orders[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.deliveryOrderDetails,
                arguments: {'orderId': orders[index].id},
              );
            },
          ),
        ),
      ),
    );
  }
}

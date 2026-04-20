import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_details_content.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderDetailsBloc>();

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.orderDetails),
      body: MultiBlocListener(
        listeners: [
          BlocListener<OrderDetailsBloc, OrderDetailsState>(
            listenWhen: (prev, cur) {
              if (cur is! OrderDetailsLoaded) return false;
              if (prev is! OrderDetailsLoaded) return false;
              final wasCancelled =
                  OrderStatus.fromString(prev.order.status) ==
                  OrderStatus.cancelled;
              final nowCancelled =
                  OrderStatus.fromString(cur.order.status) ==
                  OrderStatus.cancelled;
              return !wasCancelled && nowCancelled && !cur.isCancelling;
            },
            listener: (context, _) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppTranslation.orderCancelledSuccessfully),
                ),
              );
            },
          ),
          BlocListener<OrderDetailsBloc, OrderDetailsState>(
            listenWhen: (prev, cur) {
              if (cur is! OrderDetailsLoaded) return false;
              final err = cur.actionError;
              return err != null && err.isNotEmpty;
            },
            listener: (context, state) {
              final msg = (state as OrderDetailsLoaded).actionError ?? '';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg.tr()),
                  backgroundColor: Colors.red,
                ),
              );
              context.read<OrderDetailsBloc>().add(
                    const ClearOrderDetailsTransientEvent(),
                  );
            },
          ),
        ],
        child: BlocStateHandler<OrderDetailsBloc, OrderDetailsState>(
          bloc: bloc,
          isLoading: (state) => state is OrderDetailsLoading,
          isError: (state) => state is OrderDetailsError,
          getErrorMessage: (state) => (state as OrderDetailsError).message,
          isSuccess: (state) => state is OrderDetailsLoaded,
          getRetryCallback: (_) => () {
            bloc.add(GetOrderDetailsEvent(widget.orderId));
          },
          successBuilder: (context, detailsState) {
            final loaded = detailsState as OrderDetailsLoaded;
            return OrderDetailsContent(
              order: loaded.order,
              isCancelling: loaded.isCancelling,
            );
          },
        ),
      ),
    );
  }
}

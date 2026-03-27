import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/order/order_details/presentation/widgets/order_details_content.dart';

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
      body: BlocStateHandler<OrderDetailsBloc, OrderDetailsState>(
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
          return OrderDetailsContent(order: loaded.order);
        },
      ),
    );
  }
}

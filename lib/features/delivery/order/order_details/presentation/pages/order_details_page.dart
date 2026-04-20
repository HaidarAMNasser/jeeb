import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/confirmation_dialog.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/bloc/order_details_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/widgets/order_details_content.dart';
import 'package:jeeb_app/features/get_settings/data/repositories/get_settings_repository.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String? _supportPhone;

  @override
  void initState() {
    super.initState();
    _loadSupportPhone();
  }

  Future<void> _loadSupportPhone() async {
    final repository = di.sl<GetSettingsRepository>();
    final result = await repository.getSettings();
    if (!mounted) return;
    result.fold(
      (_) {},
      (settings) {
        final phone = settings.supportPhone.trim();
        if (phone.isEmpty) return;
        setState(() => _supportPhone = phone);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderDetailsBloc>();

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.orderDetails),
      bottomNavigationBar: BlocBuilder<OrderDetailsBloc, OrderDetailsState>(
        builder: (context, state) {
          if (state is! OrderDetailsLoaded) return const SizedBox.shrink();
          final routeStatus = OrderStatus.fromString(state.order.status);
          if (!routeStatus.canClientCancelOrder) return const SizedBox.shrink();

          return Material(
            color: ColorManager.background,
            surfaceTintColor: Colors.transparent,
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.fromLTRB(
                AppPadding.p16,
                AppPadding.p8,
                AppPadding.p16,
                AppPadding.p16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorManager.textPrimary,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    side: BorderSide(
                      color:
                          ColorManager.textSecondary.withValues(alpha: 0.55),
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: AppPadding.p12,
                      horizontal: AppPadding.p14,
                    ),
                    disabledForegroundColor:
                        ColorManager.textPrimary.withValues(alpha: 0.4),
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return ColorManager.primary.withValues(alpha: 0.12);
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return ColorManager.primary.withValues(alpha: 0.06);
                      }
                      return Colors.transparent;
                    }),
                  ),
                onPressed: state.isCancelling
                    ? null
                    : () {
                        ConfirmationDialog.show(
                          context: context,
                          title: AppTranslation.areYouSureCancelOrder,
                          confirmText: AppTranslation.cancelOrder,
                          confirmColor: ColorManager.errorColor,
                          onConfirm: () {
                            context.read<OrderDetailsBloc>().add(
                                  const CancelOrderEvent(),
                                );
                          },
                        );
                      },
                child: state.isCancelling
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorManager.textPrimary,
                        ),
                      )
                    : Text(AppTranslation.cancelOrder),
                ),
              ),
            ),
          );
        },
      ),
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
              supportPhone: _supportPhone,
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket_order_location_session.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/checkout_location_pick.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_empty_state.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_confirmation_flow_helper.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_loaded_content.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/presentation/bloc/order_before_confirm_bloc.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class BasketPage extends StatefulWidget {
  final bool? removeBack;
  const BasketPage({super.key, this.removeBack});

  @override
  State<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  bool _isPickingLocation = false;

  String _price(int value) => (value / 100).toStringAsFixed(2);

  Future<void> _onCreateOrderPressed(
    BuildContext context,
    ListCartLoaded cart,
  ) async {
    final ownerId = int.tryParse(cart.merchantOwnerId ?? '');
    if (ownerId == null) {
      customToast(msg: AppTranslation.orderOwnerRequired);
      return;
    }

    // Capture before long async (permission / map); avoids missing dispatch if
    // [context.mounted] is briefly false after the system dialog.
    final orderBloc = context.read<OrderBeforeConfirmBloc>();

    if (!BasketOrderLocationSession.hasCoordinates) {
      setState(() => _isPickingLocation = true);
      try {
        final picked = await pickCheckoutLocation(context);
        if (picked == null) return;
        BasketOrderLocationSession.save(picked.lat, picked.lng);
      } finally {
        if (mounted) {
          setState(() => _isPickingLocation = false);
        }
      }
    }

    if (!BasketOrderLocationSession.hasCoordinates) return;

    final lat = BasketOrderLocationSession.latitude!;
    final lng = BasketOrderLocationSession.longitude!;

    final productRequests = <OrderBeforeConfirmProductRequest>[];
    for (final item in cart.currentItems) {
      if (item.isOffer) continue;
      final id = int.tryParse(item.productId);
      if (id == null) continue;
      productRequests.add(
        OrderBeforeConfirmProductRequest(
          productId: id,
          quantity: item.quantity,
        ),
      );
    }

    orderBloc.add(
      FetchOrderDataBeforeConfirm(
        merchantId: ownerId,
        latitude: lat,
        longitude: lng,
        products: productRequests,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBeforeConfirmBloc, OrderBeforeConfirmState>(
      listenWhen: (prev, curr) =>
          curr is OrderBeforeConfirmSuccess ||
          curr is OrderBeforeConfirmFailure,
      listener: (context, orderState) {
        if (orderState is OrderBeforeConfirmFailure) {
          customToast(msg: orderState.message);
          return;
        }
        if (orderState is OrderBeforeConfirmSuccess) {
          final cart = context.read<ListCartBloc>().state;
          if (cart is! ListCartLoaded) return;
          final preview = orderState.preview;
          final orderBloc = context.read<OrderBeforeConfirmBloc>();
          Future.microtask(() async {
            await BasketConfirmationFlowHelper.open(
              context,
              cart,
              deliveryPreview: preview,
            );
            if (context.mounted) {
              orderBloc.add(const OrderBeforeConfirmReset());
            }
          });
        }
      },
      child: BlocBuilder<OrderBeforeConfirmBloc, OrderBeforeConfirmState>(
        buildWhen: (prev, curr) =>
            prev.runtimeType != curr.runtimeType ||
            curr is OrderBeforeConfirmLoading,
        builder: (context, orderState) {
          final orderLoading = orderState is OrderBeforeConfirmLoading;
          return BlocConsumer<ListCartBloc, ListCartState>(
            listener: (context, state) {
              if (state is ListCartLoaded && state.noticeMessage != null) {
                customToast(msg: state.noticeMessage!);
                context.read<ListCartBloc>().add(const ClearCartNoticeEvent());
              }
            },
            builder: (context, state) {
              final isSaving = state is ListCartLoaded && state.isSaving;
              return ModalProgressHUD(
                inAsyncCall: isSaving || orderLoading,
                progressIndicator: const CircularProgressIndicator(
                  color: ColorManager.primary,
                ),
                child: Scaffold(
                  backgroundColor: ColorManager.background,
                  appBar: CustomAppBar(
                    title: AppTranslation.basket,
                    automaticallyImplyLeading:
                        (widget.removeBack != null && widget.removeBack!)
                        ? false
                        : true,
                    actions: [
                      IconButton(
                        onPressed: isSaving || orderLoading
                            ? null
                            : () {
                                context.read<ListCartBloc>().add(
                                  const ClearEntireCartEvent(),
                                );
                              },
                        tooltip: AppTranslation.delete,
                        icon: const Icon(
                          Icons.delete_outline_sharp,
                          color: ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                  body: BlocStateHandler<ListCartBloc, ListCartState>(
                    bloc: context.read<ListCartBloc>(),
                    isLoading: (state) =>
                        state is ListCartLoading || state is ListCartInitial,
                    isError: (state) => state is ListCartError,
                    getErrorMessage: (state) =>
                        (state as ListCartError).message,
                    isSuccess: (state) => state is ListCartLoaded,
                    isEmpty: (state) =>
                        state is ListCartLoaded && state.isEmpty,
                    emptyBuilder: (_) => const BasketEmptyState(),
                    getRetryCallback: (_) => () {
                      context.read<ListCartBloc>().add(const LoadCartEvent());
                    },
                    successBuilder: (context, loadedState) {
                      final loaded = loadedState as ListCartLoaded;
                      return BasketLoadedContent(
                        state: loaded,
                        isCreatingOrder: _isPickingLocation,
                        priceFormatter: _price,
                        onIncrease: (item) => context.read<ListCartBloc>().add(
                          IncreaseCartItemEvent(
                            item.productId,
                            isOffer: item.isOffer,
                          ),
                        ),
                        onDecrease: (item) => context.read<ListCartBloc>().add(
                          DecreaseCartItemEvent(
                            item.productId,
                            isOffer: item.isOffer,
                          ),
                        ),
                        onSaveChanges: () => context.read<ListCartBloc>().add(
                          const SaveCartChangesEvent(),
                        ),
                        onCreateOrder: () {
                          if (_isPickingLocation) return;
                          _onCreateOrderPressed(context, loaded);
                        },
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

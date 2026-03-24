import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket/widgets/basket_empty_state.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket/widgets/basket_confirmation_flow_helper.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/basket/widgets/basket_loaded_content.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  String _price(int value) => (value / 100).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
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
          inAsyncCall: isSaving,
          progressIndicator: const CircularProgressIndicator(
            color: ColorManager.primary,
          ),
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: CustomAppBar(
              title: AppTranslation.basket,
              actions: [
                IconButton(
                  onPressed: isSaving
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
              getErrorMessage: (state) => (state as ListCartError).message,
              isSuccess: (state) => state is ListCartLoaded,
              isEmpty: (state) => state is ListCartLoaded && state.isEmpty,
              emptyBuilder: (_) => const BasketEmptyState(),
              getRetryCallback: (_) => () {
                context.read<ListCartBloc>().add(const LoadCartEvent());
              },
              successBuilder: (context, loadedState) {
                final state = loadedState as ListCartLoaded;
                return BasketLoadedContent(
                  state: state,
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
                  onCreateOrder: () =>
                      BasketConfirmationFlowHelper.open(context, state),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

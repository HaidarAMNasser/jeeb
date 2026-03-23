import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/location_permission_helper.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/features/auth/profile/presentation/widgets/location_map_picker_page.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/basket/confirmation/presentation/models/confirmation_item.dart';
import 'package:jeeb_app/features/basket/confirmation/presentation/pages/basket_confirmation_page.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_empty_state.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_item_card.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_save_bar.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_summary_card.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/location_choice_dialog.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  String _price(int value) => (value / 100).toStringAsFixed(2);

  Future<void> _openLocationAndGoToConfirmation(
    BuildContext context,
    ListCartLoaded state,
  ) async {
    final action = await showDialog<LocationChoice>(
      context: context,
      builder: (_) => const LocationChoiceDialog(),
    );
    if (action == null) return;

    double? lat;
    double? lng;

    if (action == LocationChoice.current) {
      final res = await LocationPermissionHelper.requestAndGetPosition();
      lat = res.latitude;
      lng = res.longitude;
      if (lat == null || lng == null) {
        customToast(msg: AppTranslation.locationUnavailable);
        return;
      }
    } else {
      final picked = await Navigator.of(context).push<LocationMapPickerResult>(
        MaterialPageRoute(builder: (_) => const LocationMapPickerPage()),
      );
      if (picked == null) return;
      lat = picked.latitude;
      lng = picked.longitude;
    }

    if (!context.mounted) return;
    final confirmationItems = state.currentItems
        .map(
          (item) => ConfirmationItem(
            productName: item.productName,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        )
        .toList(growable: false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BasketConfirmationPage(
          items: confirmationItems,
          merchantName: state.merchantName,
          latitude: lat!,
          longitude: lng!,
          initialPhone: state.customerPhone,
        ),
      ),
    );
  }

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
                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.all(AppPadding.p16),
                        children: [
                          BasketSummaryCard(
                            items: state.currentItems,
                            total: state.total,
                            merchantName: state.merchantName,
                            priceFormatter: _price,
                          ),
                          SizedBox(height: AppHeight.s16),
                          ...state.currentItems.map(
                            (item) => BasketItemCard(
                              item: item,
                              priceFormatter: _price,
                              onIncrease: () => context
                                  .read<ListCartBloc>()
                                  .add(IncreaseCartItemEvent(item.productId)),
                              onDecrease: () => context
                                  .read<ListCartBloc>()
                                  .add(DecreaseCartItemEvent(item.productId)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isDirty)
                      BasketSaveBar(
                        onSave: () => context.read<ListCartBloc>().add(
                          const SaveCartChangesEvent(),
                        ),
                      )
                    else
                      BasketSaveBar(
                        label: AppTranslation.createOrder,
                        onSave: () =>
                            _openLocationAndGoToConfirmation(context, state),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

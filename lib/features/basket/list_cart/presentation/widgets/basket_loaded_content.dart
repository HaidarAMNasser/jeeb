import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_item_card.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_save_bar.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/widgets/basket_summary_card.dart';

class BasketLoadedContent extends StatelessWidget {
  final ListCartLoaded state;
  final String Function(int) priceFormatter;
  final void Function(CartDraftItem item) onIncrease;
  final void Function(CartDraftItem item) onDecrease;
  final VoidCallback onSaveChanges;
  final VoidCallback onCreateOrder;

  const BasketLoadedContent({
    super.key,
    required this.state,
    required this.priceFormatter,
    required this.onIncrease,
    required this.onDecrease,
    required this.onSaveChanges,
    required this.onCreateOrder,
  });

  @override
  Widget build(BuildContext context) {
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
                priceFormatter: priceFormatter,
              ),
              SizedBox(height: AppHeight.s16),
              ...state.currentItems.map(
                (item) => BasketItemCard(
                  item: item,
                  priceFormatter: priceFormatter,
                  onIncrease: () => onIncrease(item),
                  onDecrease: () => onDecrease(item),
                ),
              ),
            ],
          ),
        ),
        if (state.isDirty)
          BasketSaveBar(onSave: onSaveChanges)
        else
          BasketSaveBar(
            label: AppTranslation.createOrder,
            onSave: onCreateOrder,
          ),
      ],
    );
  }
}

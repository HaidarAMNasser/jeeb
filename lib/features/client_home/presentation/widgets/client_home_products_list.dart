import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/empty_state_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_cubit.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_state.dart';

/// Vertical list of product cards.
class ClientHomeProductsList extends StatelessWidget {
  const ClientHomeProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientHomeCubit, ClientHomeState>(
      buildWhen: (a, b) => a.products != b.products,
      builder: (context, state) {
        final products = state.products;
        if (products.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppHeight.s32),
            child: EmptyStateWidget(message: AppTranslation.noProductsFound),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          separatorBuilder: (_, __) => SizedBox(height: AppHeight.s12),
          itemBuilder: (context, index) {
            return ProductListItem(product: products[index]);
          },
        );
      },
    );
  }
}

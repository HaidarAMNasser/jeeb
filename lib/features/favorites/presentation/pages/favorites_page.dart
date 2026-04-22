import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class FavoritesPage extends StatefulWidget {
  final bool? removeBack;
  const FavoritesPage({super.key, this.removeBack});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _wasToggling = false;

  void _listener(BuildContext context, FavoritesState state) {
    if (state is FavoritesLoaded) {
      if (state.togglingProductIds.isNotEmpty) {
        _wasToggling = true;
      } else if (_wasToggling && context.mounted) {
        _wasToggling = false;
        context.read<FavoritesBloc>().add(const LoadFavoritesEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FavoritesBloc, FavoritesState>(
      listener: _listener,
      child: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          final isToggling =
              state is FavoritesLoaded && state.togglingProductIds.isNotEmpty;

          return ModalProgressHUD(
            inAsyncCall: isToggling,
            progressIndicator: const CircularProgressIndicator(
              color: ColorManager.primary,
            ),
            child: Scaffold(
              backgroundColor: ColorManager.background,
              appBar: CustomAppBar(
                title: AppTranslation.favorites,
                automaticallyImplyLeading:
                    (widget.removeBack != null && widget.removeBack!) ? false : true,
              ),
              body: BlocStateHandler<FavoritesBloc, FavoritesState>(
                bloc: context.read<FavoritesBloc>(),
                isLoading: (s) => s is FavoritesLoading,
                isError: (s) => s is FavoritesError,
                getErrorMessage: (s) => (s as FavoritesError).message,
                isSuccess: (s) => s is FavoritesLoaded,
                isEmpty: (s) => s is FavoritesLoaded && s.products.isEmpty,
                emptyMessage: AppTranslation.noFavoritesFound,
                getRetryCallback: (_) =>
                    () => context.read<FavoritesBloc>().add(
                      const LoadFavoritesEvent(),
                    ),
                successBuilder: (context, state) {
                  final loaded = state as FavoritesLoaded;
                  final List<ProductEntity> products = loaded.products;
                  final favBloc = context.read<FavoritesBloc>();
                  return ListView.separated(
                    padding: EdgeInsets.all(AppPadding.p16),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppHeight.s12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductListItem(
                        product: product,
                        isFavorite: true,
                        isTogglingFavorite: loaded.isToggling(product.id),
                        onToggleFavorite: () =>
                            favBloc.add(ToggleFavoriteEvent(product.id)),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

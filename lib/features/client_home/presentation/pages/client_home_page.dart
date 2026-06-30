import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_event.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client/client_home_app_bar.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client_home_search_bar.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/category/client_home_categories_section.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/merchants/client_home_merchants_section.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/offer/client_home_offers_slider.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client/client_home_products_list.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ClientHomeBloc>().add(const LoadClientHomeEvent());
    context.read<FavoritesBloc>().add(const LoadFavoritesEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ClientHomeBloc>().add(const LoadMoreProductsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: const ClientHomeAppBar(),
      body: BlocBuilder<ClientHomeBloc, ClientHomeState>(
        builder: (context, state) {
          if (state.errorMessage != null && state.categories.isEmpty) {
            return ErrorStateWidget(
              message: state.errorMessage!,
              onRetry: () => context.read<ClientHomeBloc>().add(
                const LoadClientHomeEvent(),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ClientHomeBloc>().add(
                const RefreshClientHomeEvent(),
              );
            },
            color: ColorManager.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(AppPadding.p16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const ClientHomeSearchBar(),
                      SizedBox(height: AppHeight.s22),
                      const ClientHomeCategoriesSection(),
                      SizedBox(height: AppHeight.s10),

                      const ClientHomeOffersSlider(),
                      SizedBox(height: AppHeight.s10),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                  sliver: const SliverToBoxAdapter(
                    child: ClientHomeMerchantsSection(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppPadding.p16,
                    AppHeight.s16,
                    AppPadding.p16,
                    0,
                  ),
                  sliver: const SliverToBoxAdapter(
                    child: ClientHomeProductsList(),
                  ),
                ),
                if (state.isLoadingMore)
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    sliver: SliverToBoxAdapter(
                      child: Center(child: CustomCircleIndicator()),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: AppHeight.s24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

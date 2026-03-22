import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_event.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client/client_home_search_bar.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client/client_home_categories_section.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/merchants/client_home_merchants_section.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/offer/client_home_offers_slider.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client/client_home_products_list.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';

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
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleSpacing: AppPadding.p16,
        title: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            String name = "";
            if (state is ProfileLoaded) {
              name = state.user.firstName;
            }
            final displayName = name.trim().isEmpty ? "there" : name.trim();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Welcome back",
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.textSecondary,
                  ),
                ),
                SizedBox(height: AppHeight.s2_5),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Hello, ",
                        style: getSemiBoldStyle(
                          fontSize: AppFontSize.s20,
                          color: ColorManager.titlesColor.withOpacity(0.85),
                        ),
                      ),
                      TextSpan(
                        text: displayName,
                        style: getBoldStyle(
                          fontSize: AppFontSize.s20,
                          color: ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              String? imageUrl;
              if (state is ProfileLoaded) {
                imageUrl = state.user.profileImageUrl;
              }
              return Padding(
                padding: EdgeInsets.only(left: AppPadding.p16),
                child: GestureDetector(
                  onTap: () {
                    AppRouter.navigateTo(context, Routes.profile);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorManager.surface,
                      border: Border.all(
                        color: ColorManager.primary.withOpacity(0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? CustomCachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.person, color: ColorManager.primary),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
                    delegate: SliverChildListDelegate(() {
                      final children = <Widget>[
                        const ClientHomeSearchBar(),
                        SizedBox(height: AppHeight.s24),
                        const ClientHomeCategoriesSection(),
                        SizedBox(height: AppHeight.s24),
                      ];
                      children.addAll([
                        const ClientHomeMerchantsSection(),
                        SizedBox(height: AppHeight.s24),
                        const ClientHomeOffersSlider(),
                        SizedBox(height: AppHeight.s24),
                      ]);
                      return children;
                    }()),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
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

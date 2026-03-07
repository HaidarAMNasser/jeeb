import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/bloc/list_merchant_bloc.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/widgets/merchant_list_item.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/widgets/search_merchant_widget.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';

class ListMerchantPage extends StatefulWidget {
  const ListMerchantPage({super.key});

  @override
  State<ListMerchantPage> createState() => _ListMerchantPageState();
}

class _ListMerchantPageState extends State<ListMerchantPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial merchants
    context.read<ListMerchantBloc>().add(const GetMerchantsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<ListMerchantBloc>().state;
    // Prevent loading more if already loading
    if (state is ListMerchantLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (state is ListMerchantLoaded && state.hasMore) {
        // Use the search query from state when loading more
        context.read<ListMerchantBloc>().add(
          GetMerchantsEvent(loadMore: true, search: state.search),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.merchants),
      body: BlocBuilder<ListMerchantBloc, ListMerchantState>(
        builder: (context, state) {
          // Get current search query from state for refresh
          String? currentSearch;
          if (state is ListMerchantLoaded) {
            currentSearch = state.search;
          } else if (state is ListMerchantLoadingMore) {
            currentSearch = state.search;
          }

          // return BlocStateHandler<ListMerchantBloc, ListMerchantState>(
          //   bloc: context.read<ListMerchantBloc>(),
          //   isLoading: (state) => state is ListMerchantLoading,
          //   isError: (state) => state is ListMerchantError,
          //   getErrorMessage: (state) => (state as ListMerchantError).message,
          //   isSuccess: (state) =>
          //       state is ListMerchantLoaded || state is ListMerchantLoadingMore,
          //   isEmpty: (state) {
          //     if (state is ListMerchantLoaded) {
          //       return state.merchants.isEmpty;
          //     }
          //     if (state is ListMerchantLoadingMore) {
          //       return state.merchants.isEmpty;
          //     }
          //     return false;
          //   },
          //   emptyMessage: AppTranslation.noMerchantsFound,
          //   getRetryCallback: (state) => () {
          //     context.read<ListMerchantBloc>().add(const GetMerchantsEvent());
          //   },
          //   successBuilder: (context, merchantState) {
          //     final merchants = merchantState is ListMerchantLoaded
          //         ? merchantState.merchants
          //         : (merchantState as ListMerchantLoadingMore).merchants;
          //     final hasMore = merchantState is ListMerchantLoaded
          //         ? merchantState.hasMore
          //         : false;

          //     return Column(
          //       children: [
          //         // Search field
          //         const SearchMerchantWidget(),
          //         Expanded(
          //           child: RefreshIndicator(
          //             onRefresh: () async {
          //               context.read<ListMerchantBloc>().add(
          //                 GetMerchantsEvent(search: currentSearch),
          //               );
          //             },
          //             child: ListView.builder(
          //               controller: _scrollController,
          //               padding: EdgeInsets.symmetric(
          //                 horizontal: AppPadding.p16,
          //               ),
          //               itemCount: merchants.length + (hasMore ? 1 : 0),
          //               itemBuilder: (context, index) {
          //                 if (index == merchants.length) {
          //                   return Padding(
          //                     padding: EdgeInsets.all(AppPadding.p16),
          //                     child: const CustomCircleIndicator(),
          //                   );
          //                 }
          //                 final merchant = merchants[index];
          //                 return MerchantListItem(merchant: merchant);
          //               },
          //             ),
          //           ),
          //         ),
          //       ],
          //     );
          //   },
          // );

          // Fake data ListView for UI testing with search
          final fakeMerchants = _generateFakeMerchants();
          final searchQuery = currentSearch?.toLowerCase() ?? '';
          final filteredMerchants = searchQuery.isEmpty
              ? fakeMerchants
              : fakeMerchants
                    .where(
                      (merchant) =>
                          merchant.name.toLowerCase().contains(searchQuery) ||
                          merchant.email.toLowerCase().contains(searchQuery),
                    )
                    .toList();

          return Column(
            children: [
              // Search field
              const SearchMerchantWidget(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<ListMerchantBloc>().add(
                      GetMerchantsEvent(search: currentSearch),
                    );
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                    itemCount: filteredMerchants.length,
                    itemBuilder: (context, index) {
                      final merchant = filteredMerchants[index];
                      return MerchantListItem(merchant: merchant);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Fake data generation for UI testing
List<MerchantEntity> _generateFakeMerchants() {
  final merchantNames = [
    'Al-Rashid Restaurant',
    'Golden Fork Cafe',
    'Mediterranean Delight',
    'Spice Garden',
    'Ocean View Seafood',
    'Royal Palace Restaurant',
    'Sunset Grill',
    'City Lights Bistro',
    'Mountain View Cafe',
    'Desert Oasis',
    'Green Valley Restaurant',
    'Blue Moon Diner',
    'Star Light Cafe',
    'Diamond Restaurant',
    'Pearl Harbor Seafood',
    'Crystal Palace',
    'Emerald Garden',
    'Ruby Red Bistro',
    'Sapphire Cafe',
    'Topaz Restaurant',
    'Amber Grill',
    'Coral Reef Seafood',
    'Ivory Tower Cafe',
    'Marble Hall Restaurant',
    'Granite Stone Grill',
  ];

  final cities = ['Beirut', 'Tripoli', 'Sidon', 'Tyre', 'Byblos', 'Zahle'];
  final countries = [
    'Lebanon',
    'Lebanon',
    'Lebanon',
    'Lebanon',
    'Lebanon',
    'Lebanon',
  ];

  return List.generate(25, (index) {
    final nameIndex = index % merchantNames.length;
    final cityIndex = index % cities.length;

    return MerchantEntity(
      id: '${index + 1}',
      name: merchantNames[nameIndex],
      email:
          '${merchantNames[nameIndex].toLowerCase().replaceAll(' ', '_')}@example.com',
      cityName: cities[cityIndex],
      countryName: countries[cityIndex],
      phoneNumber: '+961 ${3 + (index % 7)}${1000000 + index}',
      image: 'https://picsum.photos/seed/merchant${index + 1}/200/200',
    );
  });
}

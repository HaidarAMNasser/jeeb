import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';
import '../../../../core/presentation/widgets/custom_app_bar.dart';
import '../../../../core/presentation/widgets/custom_circle_indicator.dart';
import '../bloc/offers_bloc.dart';
import '../widgets/offer_item_widget.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final ScrollController _scrollController = ScrollController();
  late OffersBloc _offersBloc;

  @override
  void initState() {
    super.initState();
    _offersBloc = context.read<OffersBloc>();
    _offersBloc.add(const FetchOffers());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final state = _offersBloc.state;
      if (state is OffersStateLoaded && !state.hasReachedMax) {
        _offersBloc.add(const LoadMoreOffers());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(
        title: 'Offers',
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<OffersBloc, OffersState>(
        builder: (context, state) {
          if (state is OffersStateLoading) {
            return const Center(
              child: CustomCircleIndicator(),
            );
          }

          if (state is OffersStateError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ColorManager.error,
                  ),
                  SizedBox(height: AppHeight.s16),
                  Text(
                    'Error loading offers',
                    style: getBoldStyle(
                      fontSize: AppFontSize.s18,
                      color: ColorManager.error,
                    ),
                  ),
                  SizedBox(height: AppHeight.s8),
                  Text(
                    state.message,
                    style: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppHeight.s24),
                  ElevatedButton(
                    onPressed: () {
                      _offersBloc.add(const FetchOffers());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: ColorManager.surface,
                    ),
                    child: Text(
                      'Retry',
                      style: getMediumStyle(
                        fontSize: AppFontSize.s14,
                        color: ColorManager.surface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is OffersStateLoaded) {
            if (state.offers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 64,
                      color: ColorManager.textSecondary,
                    ),
                    SizedBox(height: AppHeight.s16),
                    Text(
                      'No offers available',
                      style: getBoldStyle(
                        fontSize: AppFontSize.s18,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppHeight.s8),
                    Text(
                      'Check back later for new offers',
                      style: getRegularStyle(
                        fontSize: AppFontSize.s14,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _offersBloc.add(const FetchOffers());
              },
              child: Column(
                children: [
                  // Summary header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppPadding.p16),
                    decoration: BoxDecoration(
                      color: ColorManager.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Offers',
                                style: getRegularStyle(
                                  fontSize: AppFontSize.s12,
                                  color: ColorManager.textSecondary,
                                ),
                              ),
                              SizedBox(height: AppHeight.s4),
                              Text(
                                '${state.pagination.total}',
                                style: getBoldStyle(
                                  fontSize: AppFontSize.s20,
                                  color: ColorManager.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppPadding.p12,
                            vertical: AppHeight.s8,
                          ),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.r8),
                          ),
                          child: Text(
                            'Page ${state.pagination.page} of ${state.pagination.totalPages}',
                            style: getMediumStyle(
                              fontSize: AppFontSize.s12,
                              color: ColorManager.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Offers list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(AppPadding.p16),
                      itemCount: state.offers.length + (state.hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index == state.offers.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CustomCircleIndicator(),
                            ),
                          );
                        }
                        
                        return OfferItemWidget(offer: state.offers[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_cubit.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_state.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client_home_search_bar.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client_home_categories_section.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client_home_merchants_section.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client_home_offers_slider.dart';
import 'package:jeeb_app/features/client_home/presentation/widgets/client_home_products_list.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  @override
  void initState() {
    super.initState();
    context.read<ClientHomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: BlocBuilder<ClientHomeCubit, ClientHomeState>(
          builder: (context, state) {
            if (state == null) {
              return const Center(child: CustomCircleIndicator());
            }
            if (state.isLoading && state.categories.isEmpty) {
              return const Center(child: CustomCircleIndicator());
            }
            if (state.errorMessage != null && state.categories.isEmpty) {
              return ErrorStateWidget(
                message: state.errorMessage!,
                onRetry: () => context.read<ClientHomeCubit>().refresh(),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<ClientHomeCubit>().refresh(),
              color: ColorManager.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppPadding.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClientHomeSearchBar(),
                    SizedBox(height: AppHeight.s24),
                    const ClientHomeCategoriesSection(),
                    SizedBox(height: AppHeight.s24),
                    const ClientHomeMerchantsSection(),
                    SizedBox(height: AppHeight.s24),
                    const ClientHomeOffersSlider(),
                    SizedBox(height: AppHeight.s24),
                    const ClientHomeProductsList(),
                    SizedBox(height: AppHeight.s24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

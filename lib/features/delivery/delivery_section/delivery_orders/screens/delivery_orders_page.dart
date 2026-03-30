import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import '../widgets/delivery_orders_tab_content.dart';

class DeliveryOrdersPage extends StatelessWidget {
  const DeliveryOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: ColorManager.background,
        appBar: AppBar(
          backgroundColor: ColorManager.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            AppTranslation.myOrders,
            style: getBoldStyle(
              fontSize: AppFontSize.s20,
              color: ColorManager.titlesColor,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppPadding.p16),
              decoration: BoxDecoration(
                color: ColorManager.primaryDark,
                borderRadius: BorderRadius.circular(AppSize.s12),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: ColorManager.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: ColorManager.primary,
                  borderRadius: BorderRadius.circular(AppSize.s10),
                ),
                labelStyle: getSemiBoldStyle(fontSize: AppFontSize.s14),
                unselectedLabelStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                ),
                tabs: [
                  Tab(text: AppTranslation.pending),
                  Tab(text: AppTranslation.completed),
                  Tab(text: AppTranslation.cancelled),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            DeliveryOrdersTabContent(type: DeliveryOrderTabType.pending),
            DeliveryOrdersTabContent(type: DeliveryOrderTabType.completed),
            DeliveryOrdersTabContent(type: DeliveryOrderTabType.cancelled),
          ],
        ),
      ),
    );
  }
}

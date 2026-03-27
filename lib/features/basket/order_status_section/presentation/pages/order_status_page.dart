import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/bloc/order_status_bloc.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/utils/order_status_step_labels.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_badge_helper.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_hero_image.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_horizontal_timeline.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_problem_banner.dart';

/// Order tracking screen; state lives in [OrderStatusBloc] (see route).
class OrderStatusPage extends StatelessWidget {
  const OrderStatusPage({super.key});

  static const Color _bg = Color(0xFF3A3836);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: BlocBuilder<OrderStatusBloc, OrderStatusState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  OrderStatusHeroImage(timelineStepIndex: state.displayIndex),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: AppHeight.s12),
                        if (state.showProblemBanner)
                          const OrderStatusProblemBanner(),
                        OrderStatusHorizontalTimeline(
                          labels: OrderStatusStepLabels.asList(),
                          activeIndex: state.displayIndex,
                          routeStatus: state.routeStatus,
                          demoRunning: state.demoRunning,
                        ),
                        SizedBox(height: 200,),
                        Padding(
                          padding: EdgeInsets.zero,
                          // symmetric(
                          //   horizontal: AppPadding.p16,
                          //   vertical: AppSize.s10.h,
                          // ),
                          child: OrderBadgeWidget(
                            enableSmallBadge: true,
                            width: AppSize.s100.w,
                            caption: AppTranslation.orderStatusViewDetails,
                            accentColor: ColorManager.primary,
                            onTap: () {
                              AppRouter.navigateTo(
                                context,
                                Routes.orderDetails,
                                arguments: {'orderId': state.orderId},
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/order_status_step_index.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/live_tracking_map_card.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/bloc/order_status_bloc.dart';
import 'package:jeeb_app/core/common/classes/order_status_step_labels.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_badge_helper.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_hero_image.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_driver_contact_card.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_horizontal_timeline.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_problem_banner.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/get_settings/data/repositories/get_settings_repository.dart';

/// Order tracking screen; state lives in [OrderStatusBloc] (see route).
class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  String? _supportPhone;

  static const Color _bg = Color(0xFF3A3836);

  @override
  void initState() {
    super.initState();
    _loadSupportPhone();
  }

  Future<void> _loadSupportPhone() async {
    final repository = di.sl<GetSettingsRepository>();
    final result = await repository.getSettings();
    if (!mounted) return;
    result.fold(
      (_) {},
      (settings) {
        final phone = settings.supportPhone.trim();
        if (phone.isEmpty) return;
        setState(() => _supportPhone = phone);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: BlocListener<OrderStatusBloc, OrderStatusState>(
        listenWhen: (prev, curr) =>
            !orderStatusIsTerminal(prev.routeStatus) &&
            (curr.routeStatus == OrderStatus.delivered ||
                curr.routeStatus == OrderStatus.completed),
        listener: (context, state) {
          AppRouter.navigateAndReplace(
            context,
            Routes.orderDetails,
            arguments: {'orderId': state.orderId},
          );
        },
        child: BlocBuilder<OrderStatusBloc, OrderStatusState>(
          builder: (context, state) {
            final dLat = state.deliveryLatitude;
            final dLng = state.deliveryLongitude;
            final drvLat = state.driverLatitude;
            final drvLng = state.driverLongitude;
            final showLiveMap =
                state.routeStatus == OrderStatus.onTheWay &&
                ((dLat != null && dLng != null) ||
                    (drvLat != null && drvLng != null));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: OrderStatusHeroImage(
                    timelineStepIndex: state.displayIndex,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
                    child: Column(
                      spacing: AppHeight.s16,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.showProblemBanner)
                          const OrderStatusProblemBanner(),
                        OrderStatusHorizontalTimeline(
                          labels: OrderStatusStepLabels.asList(),
                          activeIndex: state.displayIndex,
                          routeStatus: state.routeStatus,
                          demoRunning: state.demoRunning,
                          deliveryManName: state.deliveryManName,
                          deliveryManPhone: state.deliveryManPhone,
                        ),
                        if (!state.demoRunning &&
                            orderStatusShowsDriverContact(
                              state.routeStatus,
                            ) &&
                            ((state.deliveryManName?.trim().isNotEmpty ??
                                    false) ||
                                (state.deliveryManPhone?.trim().isNotEmpty ??
                                    false) ||
                                (_supportPhone?.trim().isNotEmpty ?? false)))
                          OrderStatusDriverContactCard(
                            driverName: state.deliveryManName,
                            driverPhone: state.deliveryManPhone,
                            supportPhone: _supportPhone,
                          ),
                        if (showLiveMap)
                          LiveTrackingMapCard(
                            orderId: state.orderId,
                            title: AppTranslation.orderDeliveryMapBadge,
                            routeHistory: state.routeHistoryPoints,
                            deliveryLatitude: dLat,
                            deliveryLongitude: dLng,
                            driverLatitude: drvLat,
                            driverLongitude: drvLng,
                            statusLabel:
                                AppTranslation.orderStatusLabelOnTheWay,
                            statusOnline: state.driverOnline,
                          ),

                        OrderBadgeWidget(
                          normalDesign: true,
                          enableSmallBadge: true,
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
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

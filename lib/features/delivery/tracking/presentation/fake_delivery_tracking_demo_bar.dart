import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_order_location_reporter.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/fake_delivery_tracking_controller.dart';

/// QA / demo: toggles simulated GPS (same API + Firebase pipeline as real tracking).
class FakeDeliveryTrackingDemoBar extends StatelessWidget {
  const FakeDeliveryTrackingDemoBar({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    if (!DeliveryOrderLocationReporter.shouldTrack(
      OrderStatus.fromString(order.status),
    )) {
      return const SizedBox.shrink();
    }

    final fake = di.sl<FakeDeliveryTrackingController>();
    return ListenableBuilder(
      listenable: fake,
      builder: (context, _) {
        final on = fake.simulating;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppPadding.p16,
            0,
            AppPadding.p16,
            AppPadding.p12,
          ),
          child: Material(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(AppSize.s12),
            child: InkWell(
              onTap: () => fake.setSimulating(!on),
              borderRadius: BorderRadius.circular(AppSize.s12),
              child: Padding(
                padding: EdgeInsets.all(AppPadding.p12),
                child: Row(
                  children: [
                    Icon(
                      on ? Icons.stop_circle_outlined : Icons.route_outlined,
                      color: on ? Colors.deepOrange : ColorManager.primary,
                      size: AppSize.s22,
                    ),
                    SizedBox(width: AppPadding.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            on
                                ? AppTranslation.deliveryFakeGpsStop
                                : AppTranslation.deliveryFakeGpsStart,
                            style: getSemiBoldStyle(
                              fontSize: AppFontSize.s14,
                              color: ColorManager.titlesColor,
                            ),
                          ),
                          SizedBox(height: AppHeight.s4),
                          Text(
                            AppTranslation.deliveryFakeGpsHint,
                            style: getRegularStyle(
                              fontSize: AppFontSize.s11,
                              color: ColorManager.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: on,
                      activeTrackColor: ColorManager.primary.withValues(alpha: 0.45),
                      onChanged: (v) => fake.setSimulating(v),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

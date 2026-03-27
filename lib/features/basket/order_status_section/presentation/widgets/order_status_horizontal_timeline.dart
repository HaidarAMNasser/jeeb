import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_timeline_rail.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_badge_helper.dart';

/// Horizontal wavy rail + one status tile.
///
/// When [demoRunning] is true, the tile shows the animated step [labels]\[index].
/// Otherwise it shows [routeStatus.displayLabel] (API-backed).
class OrderStatusHorizontalTimeline extends StatelessWidget {
  const OrderStatusHorizontalTimeline({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.routeStatus,
    required this.demoRunning,
  });

  final List<String> labels;
  final int activeIndex;
  final OrderStatus routeStatus;
  final bool demoRunning;

  static const List<IconData> _stepIcons = [
    Icons.receipt_long_rounded,
    Icons.verified_outlined,
    Icons.search_rounded,
    Icons.takeout_dining_rounded,
    Icons.two_wheeler_rounded,
    Icons.pedal_bike_rounded,
    Icons.home_outlined,
  ];

  static const double _railHeight = 92;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    if (n == 0) return const SizedBox.shrink();
    final idx = activeIndex.clamp(0, n - 1);
    final caption = demoRunning ? labels[idx] : routeStatus.displayLabel;
    final IconData badgeIcon = demoRunning
        ? (idx < _stepIcons.length ? _stepIcons[idx] : Icons.flag_outlined)
        : routeStatus.iconData;
    final Color accent = demoRunning ? ColorManager.primary : routeStatus.color;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          OrderStatusTimelineRail(
            stepCount: n,
            activeIndex: idx,
            height: _railHeight,
          ),
          SizedBox(height: AppHeight.s16),
          OrderBadgeWidget(
            caption: caption,
            accentColor: accent,
            icon: badgeIcon,
          ),
        ],
      ),
    );
  }
}

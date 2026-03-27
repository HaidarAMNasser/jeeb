import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/utils/order_status_step_index.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_hero_image.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_problem_banner.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/widgets/order_status_horizontal_timeline.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';

/// Order tracking: subtitle app bar, hero image in card, order chip, horizontal current-only wave.
class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({
    super.key,
    required this.orderId,
    this.initialStatus = 'PENDING',
  });

  final String orderId;
  final String initialStatus;

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  bool _demoRunning = false;
  Timer? _stepTimer;
  late int _liveStepIndex;

  static const Color _bg = Color(0xFF3A3836);

  @override
  void initState() {
    super.initState();
    _liveStepIndex = _staticTimelineIndex();
  }

  @override
  void didUpdateWidget(OrderStatusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus && !_demoRunning) {
      _liveStepIndex = _staticTimelineIndex();
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  int _staticTimelineIndex() {
    final status = OrderStatus.fromString(widget.initialStatus);
    var idx = orderStatusToTimelineIndex(status);
    if (idx < 0) idx = 0;
    return idx.clamp(0, 6);
  }

  int get _displayIndex {
    if (_demoRunning) return _liveStepIndex.clamp(0, 6);
    return _staticTimelineIndex();
  }

  void _toggleDemo() {
    setState(() {
      _demoRunning = !_demoRunning;
      _stepTimer?.cancel();
      _stepTimer = null;
      if (_demoRunning) {
        _liveStepIndex = _staticTimelineIndex();
        _stepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _liveStepIndex = (_liveStepIndex + 1) % 7;
          });
        });
      }
    });
  }

  void _openOrderDetails(BuildContext context) {
    AppRouter.navigateTo(
      context,
      Routes.orderDetails,
      arguments: {'orderId': widget.orderId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromString(widget.initialStatus);
    final rawIdx = orderStatusToTimelineIndex(status);
    final problem = rawIdx < 0;

    final labels = [
      AppTranslation.orderStepPlaced,
      AppTranslation.orderStepConfirmed,
      AppTranslation.orderStepPreparing,
      AppTranslation.orderStepReady,
      AppTranslation.orderStepWithDriver,
      AppTranslation.orderStepOnTheWay,
      AppTranslation.orderStepDelivered,
    ];

    final textButtonStyle = TextButton.styleFrom(
      foregroundColor: const Color(0xFFFFF5EC),
      padding: EdgeInsets.symmetric(
        vertical: AppPadding.p12,
        horizontal: AppPadding.p8,
      ),
    );

    return Scaffold(
      backgroundColor: _bg,

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrderStatusHeroImage(timelineStepIndex: _displayIndex),

              SizedBox(height: AppHeight.s20),
              if (problem) const OrderStatusProblemBanner(),
              OrderStatusHorizontalTimeline(
                labels: labels,
                activeIndex: _displayIndex,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppPadding.p16,
                  AppPadding.p12,
                  AppPadding.p16,
                  AppPadding.p28,
                ),
                child: Column(
                  children: [
                    TextButton(
                      onPressed: _toggleDemo,
                      style: textButtonStyle,
                      child: CustomText(
                        text: _demoRunning
                            ? AppTranslation.orderStatusDemoStop
                            : AppTranslation.orderStatusDemoStart,
                        textStyle: getSemiBoldStyle(
                          fontSize: AppFontSize.s15,
                          color: const Color(0xFFFFF5EC),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openOrderDetails(context),
                      style: textButtonStyle,
                      child: CustomText(
                        text: AppTranslation.orderStatusViewDetails,
                        textStyle: getSemiBoldStyle(
                          fontSize: AppFontSize.s15,
                          color: ColorManager.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/core/presentation/widgets/error_state_widget.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_card_widgets/delivery_order_card.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/searching%20cards/delivery_searching_order_card.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class DeliveryHomeOrdersSection extends StatelessWidget {
  const DeliveryHomeOrdersSection({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onAcceptOrder,
    required this.onOrderTap,
  });

  final DeliveryHomeState state;
  final VoidCallback onRetry;
  final Future<void> Function(OrderEntity order) onAcceptOrder;
  final void Function(OrderEntity order) onOrderTap;

  @override
  Widget build(BuildContext context) {
    return _buildOrdersSliver(context);
  }

  /// SEARCHING: accept flow + searching UI. PREPARING (and others): standard order card.
  Widget _buildPipelineOrderCard(BuildContext context, OrderEntity order) {
    final status = OrderStatus.fromString(order.status);
    if (status == OrderStatus.searching) {
      return DeliverySearchingOrderCard(
        key: ValueKey('searching_${order.id}'),
        order: order,
        onTimerExpired: null,
        onTap: () {
          if (OrderStatus.fromString(order.status) == OrderStatus.searching) {
            return;
          }
          onOrderTap(order);
        },
        onAccept: () => onAcceptOrder(order),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: AppHeight.s12),
      child: DeliveryOrderCard(
        key: ValueKey('pipeline_${order.id}_${order.status}'),
        order: order,
        onTap: () => onOrderTap(order),
      ),
    );
  }

  Widget _buildOrdersSliver(BuildContext context) {
    final s = state;
    if (s is DeliveryHomeLoading || s is DeliveryHomeInitial) {
      return const SliverToBoxAdapter(child: CustomCircleIndicator());
    }
    if (s is DeliveryHomeError) {
      return SliverToBoxAdapter(
        child: ErrorStateWidget(
          message: s.message,
          onRetry: onRetry,
        ),
      );
    }
    if (s is DeliveryHomeLoaded) {
      final loadedState = s;

      if (loadedState.assignedOrder != null) {
        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionHeader(AppTranslation.activeOrders),
              DeliveryOrderCard(
                order: loadedState.assignedOrder!,
                onTap: () => onOrderTap(loadedState.assignedOrder!),
              ),
            ],
          ),
        );
      }

      if (loadedState.availableOrders.isNotEmpty) {
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: _buildSectionHeader(AppTranslation.orders),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final order = loadedState.availableOrders[index];
                  return _buildPipelineOrderCard(context, order);
                },
                childCount: loadedState.availableOrders.length,
              ),
            ),
          ],
        );
      }

      return _buildEmptyState();
    }
    return const SliverToBoxAdapter(child: CustomCircleIndicator());
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppPadding.p16,
        0,
        AppPadding.p16,
        AppPadding.p16,
      ),
      child: CustomText(
        text: title,
        textStyle: getBoldStyle(
          fontSize: AppFontSize.s20,
          color: ColorManager.titlesColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(top: AppHeight.s50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_meals_outlined,
                size: AppSize.s60,
                color: ColorManager.textSecondary.withOpacity(0.5),
              ),
              SizedBox(height: AppHeight.s16),
              CustomText(
                text: AppTranslation.noActiveOrders,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

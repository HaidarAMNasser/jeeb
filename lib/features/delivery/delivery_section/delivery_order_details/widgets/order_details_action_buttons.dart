import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/searching cards/delivery_accept_timer_badge.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/widgets/accept_delivery_estimated_time_dialog.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class DeliveryOrderActionButtons extends StatelessWidget {
  final OrderEntity order;
  final OrderStatus status;
  final VoidCallback? onRefreshOrder;
  final EdgeInsetsGeometry padding;
  final bool dense;

  const DeliveryOrderActionButtons({
    super.key,
    required this.order,
    required this.status,
    this.onRefreshOrder,
    this.padding = EdgeInsets.zero,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: BlocBuilder<ManageOrderBloc, ManageOrderState>(
        builder: (context, state) {
          final isLoading = state is ManageOrderLoading;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == OrderStatus.searching) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: AppTranslation.acceptDelivery,
                        height: AppHeight.s45,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () async {
                                final minutes =
                                    await AcceptDeliveryEstimatedTimeDialog.show(
                                  context,
                                );
                                if (!context.mounted || minutes == null) {
                                  return;
                                }
                                context.read<ManageOrderBloc>().add(
                                      AcceptDeliveryEvent(
                                        id: order.id,
                                        deliveryTime: minutes,
                                      ),
                                    );
                              },
                      ),
                    ),
                    SizedBox(width: dense ? AppWidth.s12 : AppWidth.s16),
                    DeliveryAcceptTimerBadge(
                      key: ValueKey('accept_badge_${order.id}'),
                      order: order,
                      onExpired: onRefreshOrder,
                    ),
                  ],
                ),
              ] else if (status == OrderStatus.readyForPickup)
                _buildButton(
                  text: AppTranslation.pickedUp,
                  color: ColorManager.primary,
                  icon: Icons.shopping_bag_outlined,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    ConfirmPickupEvent(
                      id: order.id,
                      reason: AppTranslation.pickedUp,
                    ),
                  ),
                )
              else if (status == OrderStatus.pickedUp)
                _buildButton(
                  text: AppTranslation.markOnTheWay,
                  color: Colors.deepOrange,
                  icon: Icons.directions_bike,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    MarkOnTheWayEvent(
                      id: order.id,
                      reason: AppTranslation.onTheWayDefaultReason,
                    ),
                  ),
                )
              else if (status == OrderStatus.onTheWay)
                _buildButton(
                  text: AppTranslation.markAsDelivered,
                  color: Colors.green,
                  icon: Icons.delivery_dining,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    MarkAsDeliveredEvent(
                      id: order.id,
                      reason: AppTranslation.handedToCustomer,
                      lat: 0,
                      lng: 0,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: dense ? AppHeight.s45 : AppHeight.s50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.s12),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    SizedBox(width: AppWidth.s8),
                  ],
                  CustomText(
                    text: text,
                    textStyle: getBoldStyle(
                      fontSize: dense ? AppFontSize.s14 : AppFontSize.s16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Backwards-compatible alias (old name used in details page).
@Deprecated('Use DeliveryOrderActionButtons')
class OrderDetailsActionButtons extends DeliveryOrderActionButtons {
  const OrderDetailsActionButtons({
    super.key,
    required super.order,
    required super.status,
    super.onRefreshOrder,
  });
}

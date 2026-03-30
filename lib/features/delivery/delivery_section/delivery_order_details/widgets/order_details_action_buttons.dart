import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_order_details/widgets/delivery_order_deadline_countdown.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsActionButtons extends StatelessWidget {
  final OrderEntity order;
  final OrderStatus status;
  final VoidCallback? onRefreshOrder;

  const OrderDetailsActionButtons({
    super.key,
    required this.order,
    required this.status,
    this.onRefreshOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: BlocBuilder<ManageOrderBloc, ManageOrderState>(
        builder: (context, state) {
          final isLoading = state is ManageOrderLoading;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (order.customerPhone != null &&
                  order.customerPhone!.isNotEmpty) ...[
                _buildButton(
                  text: '${AppTranslation.callCustomer} (${order.customerPhone})',
                  color: Colors.blueGrey,
                  icon: Icons.phone,
                  isLoading: false,
                  onPressed: () =>
                      launchUrl(Uri.parse('tel:${order.customerPhone}')),
                ),
                SizedBox(height: AppHeight.s12),
              ],
              if (status == OrderStatus.searching ||
                  status == OrderStatus.pending) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: AppTranslation.acceptDelivery,
                        height: AppHeight.s45,
                        isLoading: isLoading,
                        onPressed: () => context.read<ManageOrderBloc>().add(
                              AcceptDeliveryEvent(
                                id: order.id,
                                deliveryTime: 30,
                              ),
                            ),
                      ),
                    ),
                    SizedBox(width: AppWidth.s16),
                    DeliveryOrderDeadlineCountdown(
                      key: ValueKey(
                        '${order.id}_${order.deliveryDeadline}_${order.remainingTime?.text?.text}_${order.remainingTime?.text?.minutes}_${order.remainingTime?.text?.seconds}',
                      ),
                      order: order,
                      onExpired: onRefreshOrder,
                    ),
                  ],
                ),
              ] else if (status == OrderStatus.readyForPickup)
                _buildButton(
                  text: AppTranslation.acceptDelivery,
                  color: ColorManager.primary,
                  icon: Icons.check_circle_outline,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    AcceptDeliveryEvent(id: order.id, deliveryTime: 30),
                  ),
                )
              else if (status == OrderStatus.assigned) ...[
                _buildButton(
                  text: AppTranslation.confirmPickup,
                  color: Colors.blue,
                  icon: Icons.shopping_bag_outlined,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    ConfirmPickupEvent(id: order.id, reason: AppTranslation.pickedUp),
                  ),
                ),
                SizedBox(height: AppHeight.s12),
                _buildButton(
                  text: AppTranslation.rejectDelivery,
                  color: Colors.red,
                  icon: Icons.cancel_outlined,
                  isLoading: isLoading,
                  onPressed: () => context.read<ManageOrderBloc>().add(
                    RejectDeliveryEvent(
                      id: order.id,
                      reason: AppTranslation.unableToDeliver,
                    ),
                  ),
                ),
              ] else if (status == OrderStatus.pickedUp)
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
      height: AppHeight.s50,
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
                      fontSize: AppFontSize.s16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

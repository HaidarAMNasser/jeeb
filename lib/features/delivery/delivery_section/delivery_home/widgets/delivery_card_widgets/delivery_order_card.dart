import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:flutter/services.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:url_launcher/url_launcher.dart';
import 'delivery_order_header.dart';
import 'delivery_order_merchant.dart';
import '../delivery_order_items_list.dart';
import 'delivery_order_price_section.dart';

class DeliveryOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  const DeliveryOrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Calculate total price from products
    final totalPrice = order.products.fold<int>(
      0,
      (sum, p) => sum + p.displayPrice,
    );

    // Merchant (Restaurant) info — prefer API `owner.restaurantName`
    final fromOwner = order.owner?.restaurantName?.trim();
    final restaurantName = (fromOwner != null && fromOwner.isNotEmpty)
        ? fromOwner
        : (order.products.isNotEmpty
            ? order.products.first.merchantName ?? AppTranslation.restaurantName
            : AppTranslation.restaurantName);

    // Recipient (Customer) info
    final recipientName =
        order.customerName ??
        (order.deliveryMan?.name ?? AppTranslation.customer);
    final recipientAddress =
        order.deliveryAddress ?? (order.deliveryMan?.cityName ?? '');

    // Get delivery fees from order entity
    final deliveryFee = (order.deliveryFee ?? 0).toInt();
    final deliveryEarning = (order.deliveryEarning ?? 0).toInt();
    final preparationMinutes = order.preparationTime ?? 15;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
      child: Material(
        color: ColorManager.primaryDark,
        borderRadius: BorderRadius.circular(AppSize.s24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.s24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.s24),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSize.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(AppPadding.p20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DeliveryOrderHeader(
                          recipientName: recipientName,
                          recipientAddress: recipientAddress,
                          totalPrice:
                              (order.totalPrice ??
                                      (totalPrice + deliveryFee).toDouble())
                                  .toInt(),
                        ),
                        SizedBox(height: AppHeight.s20),
                        DeliveryOrderMerchant(
                          restaurantName: restaurantName,
                          preparationDuration: Duration(
                            minutes: preparationMinutes,
                          ),
                        ),
                        SizedBox(height: AppHeight.s24),
                        DeliveryOrderItemsList(products: order.products),
                        SizedBox(height: AppHeight.s12),
                        DeliveryOrderPriceSection(
                          deliveryFee: deliveryFee,
                          deliveryEarning: deliveryEarning,
                        ),
                        if (order.merchantPhone != null &&
                            order.merchantPhone!.isNotEmpty &&
                            order.hideMerchantPhone != true) ...[
                          SizedBox(height: AppHeight.s16),
                          _buildMerchantPhone(context, order.merchantPhone!),
                        ],
                        SizedBox(height: AppHeight.s16),
                        _DeliveryOrderFooter(
                          orderId: order.id,
                          status: order.status,
                        ),
                      ],
                    ),
                  ),
                  // Driver Action Section (In-card details)
                  _buildActionSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantPhone(BuildContext context, String phone) {
    return Row(
      children: [
        Icon(
          Icons.phone_android,
          size: AppSize.s16,
          color: ColorManager.textSecondary,
        ),
        SizedBox(width: AppWidth.s8),
        CustomText(
          text: phone,
          textStyle: getMediumStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.titlesColor,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            Icons.copy_all_outlined,
            size: AppSize.s20,
            color: ColorManager.primary,
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: phone));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone copied to clipboard')),
            );
          },
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final status = OrderStatus.fromString(order.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.primary.withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: ColorManager.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (order.customerPhone != null &&
              order.customerPhone!.isNotEmpty) ...[
            _buildActionButton(
              text: '${AppTranslation.callCustomer} (${order.customerPhone})',
              color: Colors.blueGrey,
              icon: Icons.phone,
              onPressed: () =>
                  launchUrl(Uri.parse('tel:${order.customerPhone}')),
            ),
            SizedBox(height: AppHeight.s12),
          ],
          if (status == OrderStatus.assigned)
            _buildActionButton(
              text: AppTranslation.confirmPickup,
              color: Colors.blue,
              icon: Icons.shopping_bag_outlined,
              onPressed: () => context.read<ManageOrderBloc>().add(
                ConfirmPickupEvent(
                  id: order.id,
                  reason: AppTranslation.pickedUp,
                ),
              ),
            )
          else if (status == OrderStatus.pickedUp)
            _buildActionButton(
              text: AppTranslation.markAsDelivered,
              color: Colors.green,
              icon: Icons.delivery_dining,
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
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: AppHeight.s45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.s12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              SizedBox(width: AppWidth.s8),
            ],
            CustomText(
              text: text,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryOrderFooter extends StatelessWidget {
  final String orderId;
  final String? status;

  const _DeliveryOrderFooter({required this.orderId, this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: status ?? '',
          textStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s10,
            color: ColorManager.primary.withOpacity(0.7),
          ),
        ),
        CustomText(
          text: 'Order #$orderId',
          textStyle: TextStyle(
            fontSize: AppFontSize.s10,
            color: ColorManager.textSecondary.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

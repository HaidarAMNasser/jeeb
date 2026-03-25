import 'package:flutter/material.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';

class DeliveryOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback? onTap;

  const DeliveryOrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Calculate total price
    final totalPrice = order.products.fold<int>(
      0,
      (sum, p) => sum + p.displayPrice,
    );

    // Merchant (Restaurant) info
    final restaurantName = order.products.isNotEmpty
        ? order.products.first.merchantName ?? AppTranslation.restaurantName
        : AppTranslation.restaurantName;

    // Recipient (Customer) info
    final recipientName = order.deliveryMan?.name ?? AppTranslation.customer;
    final recipientAddress = order.deliveryMan?.cityName ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppPadding.p16),
        padding: EdgeInsets.all(AppPadding.p20),
        decoration: BoxDecoration(
          color: ColorManager.primaryDark,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section: Person and Restaurant
            Row(
              children: [
                _buildAvatarIcon(Icons.person, ColorManager.primary),
                SizedBox(width: AppWidth.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: recipientName,
                        textStyle: getBoldStyle(
                          fontSize: AppFontSize.s18,
                          color: ColorManager.titlesColor,
                        ),
                      ),
                      CustomText(
                        text: recipientAddress,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s12,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPriceTag(totalPrice),
              ],
            ),
            SizedBox(height: AppHeight.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: AppSize.s14,
                  color: ColorManager.primary,
                ),
                SizedBox(width: AppWidth.s4),
                SlideCountdown(
                  duration: const Duration(minutes: 30),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSize.s8),
                  ),
                  style: getSemiBoldStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.primary,
                  ),
                  separatorStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.primary,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p8,
                    vertical: AppPadding.p2,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppHeight.s8),
            Row(
              children: [
                _buildAvatarIcon(Icons.restaurant, Colors.orangeAccent),
                SizedBox(width: AppWidth.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: restaurantName,
                        textStyle: getSemiBoldStyle(
                          fontSize: AppFontSize.s16,
                          color: ColorManager.primary,
                        ),
                      ),
                      CustomText(
                        text: AppTranslation.pickUpPoint,
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s12,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppHeight.s24),

            // Divider with label
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    color: ColorManager.textSecondary,
                    thickness: 0.5,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppPadding.p12),
                  child: CustomText(
                    text: AppTranslation.orderItems,
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s12,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: ColorManager.textSecondary,
                    thickness: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppHeight.s16),

            // Items List Section
            ...order.products.map((p) => _buildItemRow(p.name, p.displayPrice)),

            SizedBox(height: AppHeight.s12),

            // Order ID Footer
            Align(
              alignment: Alignment.centerRight,
              child: CustomText(
                text: 'Order #${order.id}',
                textStyle: TextStyle(
                  fontSize: AppFontSize.s10,
                  color: ColorManager.textSecondary.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarIcon(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: AppSize.s20, color: color),
    );
  }

  Widget _buildPriceTag(int price) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(AppSize.s12),
        boxShadow: [
          BoxShadow(
            color: ColorManager.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomText(
        text: '\$${(price / 100).toStringAsFixed(2)}',
        textStyle: getBoldStyle(fontSize: AppFontSize.s14, color: Colors.white),
      ),
    );
  }

  Widget _buildItemRow(String name, int price) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: ColorManager.primary.withOpacity(0.5),
                ),
                SizedBox(width: AppWidth.s8),
                Expanded(
                  child: CustomText(
                    text: name,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.titlesColor.withOpacity(0.9),
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          CustomText(
            text: '\$${(price / 100).toStringAsFixed(2)}',
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.titlesColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

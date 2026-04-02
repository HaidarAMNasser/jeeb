import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/searching%20cards/delivery_accept_timer_badge.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/searching%20cards/delivery_order_card_utils.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class DeliverySearchingOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onAccept;
  final VoidCallback? onTap;
  final VoidCallback? onTimerExpired;

  const DeliverySearchingOrderCard({
    super.key,
    required this.order,
    required this.onAccept,
    this.onTap,
    this.onTimerExpired,
  });

  @override
  Widget build(BuildContext context) {
    final restaurantName = restaurantNameForOrder(
      order,
      AppTranslation.restaurantName,
    );
    final restaurantAddr = restaurantAddressForOrder(order);
    final clientAddr = customerAddressForOrder(order);
    final (subMinor, feeMinor) = subtotalAndFeeMinor(order);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p16,
        vertical: AppPadding.p8,
      ),
      child: Material(
        color: ColorManager.primaryDark,
        borderRadius: BorderRadius.circular(AppSize.s20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSize.s20),
          child: Container(
            padding: EdgeInsets.all(AppPadding.p16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSize.s20),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.12),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorManager.primaryDark,
                  ColorManager.primaryDark.withOpacity(0.92),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildAvatarIcon(Icons.restaurant, Colors.orangeAccent),
                    SizedBox(width: AppWidth.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: restaurantName,
                            textStyle: getSemiBoldStyle(
                              fontSize: AppFontSize.s16,
                              color: ColorManager.titlesColor,
                            ),
                          ),
                          if (restaurantAddr.isNotEmpty) ...[
                            SizedBox(height: AppHeight.s4),
                            CustomText(
                              text: restaurantAddr,
                              maxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                              textStyle: getRegularStyle(
                                fontSize: AppFontSize.s12,
                                color: ColorManager.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: AppWidth.s12),
                    DeliveryAcceptTimerBadge(
                      key: ValueKey('accept_badge_${order.id}'),
                      order: order,
                      onExpired: onTimerExpired,
                    ),
                  ],
                ),
                SizedBox(height: AppHeight.s14),
                _InfoRow(
                  icon: Icons.person,
                  iconColor: ColorManager.primary,
                  title: AppTranslation.customer,
                  subtitle: clientAddr,
                ),
                SizedBox(height: AppHeight.s14),
                Row(
                  children: [
                    Expanded(
                      child: _MoneyTile(
                        label: AppTranslation.orderSubtotal,
                        value: fmtMinor(subMinor),
                      ),
                    ),
                    SizedBox(width: AppWidth.s12),
                    Expanded(
                      child: _MoneyTile(
                        label: AppTranslation.deliveryPrice,
                        value: fmtMinor(feeMinor),
                        accent: ColorManager.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppHeight.s16),
                Row(
                  children: [
                    const Spacer(),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: AppWidth.s158),
                      child: CustomButton(
                        text: AppTranslation.acceptDelivery,
                        onPressed: onAccept,
                        height: AppHeight.s44,
                        fontSize: AppFontSize.s13,
                        borderRadius: AppRadius.r14,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAvatarIcon(icon, iconColor),
        SizedBox(width: AppWidth.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: title,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s15,
                  color: ColorManager.titlesColor,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: subtitle,
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoneyTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _MoneyTile({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    final a = accent ?? ColorManager.titlesColor;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppSize.s16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            text: label,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s10,
              color: ColorManager.textSecondary,
            ),
          ),
          SizedBox(height: AppHeight.s8),
          CustomText(
            text: value,
            textStyle: getBoldStyle(fontSize: AppFontSize.s14, color: a),
          ),
        ],
      ),
    );
  }
}

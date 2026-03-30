import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:flutter/services.dart';

class DeliveryAvailableOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onAccept;
  final VoidCallback? onTap;

  const DeliveryAvailableOrderCard({
    super.key,
    required this.order,
    required this.onAccept,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fromOwner = order.owner?.restaurantName?.trim();
    final restaurantName = (fromOwner != null && fromOwner.isNotEmpty)
        ? fromOwner
        : (order.products.isNotEmpty
            ? order.products.first.merchantName ?? AppTranslation.restaurantName
            : AppTranslation.restaurantName);

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
                color: ColorManager.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Client Info
                Row(
                  children: [
                    buildAvatarIcon(Icons.person, ColorManager.primary),
                    SizedBox(width: AppWidth.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText(
                            text: order.customerName ?? AppTranslation.customer,
                            textStyle: getBoldStyle(
                              fontSize: AppFontSize.s16,
                              color: ColorManager.titlesColor,
                            ),
                          ),
                          CustomText(
                            text: order.deliveryAddress ?? '',
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s12,
                              color: ColorManager.textSecondary,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    buildPriceTag((order.deliveryEarning ?? 0).toInt()),
                  ],
                ),
                SizedBox(height: AppHeight.s16),
                // Restaurant Info
                Row(
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
                              fontSize: AppFontSize.s14,
                              color: ColorManager.primary,
                            ),
                          ),
                          CustomText(
                            text: (order.pickupAddress?.trim().isNotEmpty == true)
                                ? order.pickupAddress!.trim()
                                : AppTranslation.pickUpPoint,
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
                // Restaurant Phone handling
                if (order.merchantPhone != null &&
                    order.merchantPhone!.isNotEmpty &&
                    order.hideMerchantPhone != true) ...[
                  SizedBox(height: AppHeight.s12),
                  _buildPhoneRow(context, order.merchantPhone!),
                ],
                SizedBox(height: AppHeight.s20),
                // Action & Timer
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: AppTranslation.acceptDelivery,
                        onPressed: onAccept,
                        height: AppHeight.s45,

                        // fontSize: AppFontSize.s14,
                      ),
                    ),
                    SizedBox(width: AppWidth.s16),
                    _buildAcceptTimer(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptTimer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Using fixed 2 min for now as requested lightweight
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p12,
            vertical: AppPadding.p6,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSize.s12),
          ),
          child: CustomText(
            text: '02:00',
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s14,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneRow(BuildContext context, String phone) {
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
}

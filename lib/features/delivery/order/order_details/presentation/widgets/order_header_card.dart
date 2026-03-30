import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

class OrderHeaderCard extends StatelessWidget {
  final OrderEntity order;

  const OrderHeaderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromString(order.status);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.p20),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite,
        borderRadius: BorderRadius.circular(AppRadius.r24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.p20,
              vertical: AppPadding.p14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorManager.primary,
                  ColorManager.primary.withValues(alpha: 0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.r32),
              boxShadow: [
                BoxShadow(
                  color: ColorManager.primary.withValues(alpha: 0.38),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: AppSize.s26,
                ),
                SizedBox(width: AppWidth.s10),
                CustomText(
                  text: '${AppTranslation.order} #${order.id}',
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (order.status != null) ...[
            SizedBox(height: AppHeight.s16),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p18,
                vertical: AppPadding.p12,
              ),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(AppRadius.r18),
                border: Border.all(
                  color: status.color.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: status.color.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(status.iconData, color: status.color, size: AppSize.s26),
                  SizedBox(width: AppWidth.s12),
                  Flexible(
                    child: CustomText(
                      text: status.displayLabel,
                      textStyle: getBoldStyle(
                        fontSize: AppFontSize.s16,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

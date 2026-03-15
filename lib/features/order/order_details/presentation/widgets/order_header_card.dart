import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';
class OrderHeaderCard extends StatelessWidget {
  final OrderEntity order;

  const OrderHeaderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromString(order.status);
    return Card(
      color: ColorManager.defaultWhite,
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: '${AppTranslation.order} #${order.id}',
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.productNameColor,
              ),
            ),
            if (order.status != null) ...[
              SizedBox(height: AppHeight.s8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.p8,
                  vertical: AppPadding.p4,
                ),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: CustomText(
                  text: status.displayLabel,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s12,
                    color: status.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


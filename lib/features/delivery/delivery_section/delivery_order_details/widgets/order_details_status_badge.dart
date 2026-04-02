import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';

class OrderDetailsStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderDetailsStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p6,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSize.s8),
        border: Border.all(color: status.color.withOpacity(0.5)),
      ),
      child: CustomText(
        text: status.displayLabel,
        textStyle: getBoldStyle(fontSize: AppFontSize.s12, color: status.color),
      ),
    );
  }
}

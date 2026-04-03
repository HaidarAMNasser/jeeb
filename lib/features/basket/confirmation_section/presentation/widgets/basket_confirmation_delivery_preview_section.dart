import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/domain/entities/order_before_confirm_preview.dart';

/// Server quote from [OrderBeforeConfirmPreview] (`calculate-delivery-cost`).
class BasketConfirmationDeliveryPreviewSection extends StatelessWidget {
  const BasketConfirmationDeliveryPreviewSection({
    super.key,
    required this.preview,
  });

  final OrderBeforeConfirmPreview preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: ColorManager.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(
            AppTranslation.orderSubtotal,
            '\$${preview.productsTotalMinorUnits}',
          ),
          _row(
            AppTranslation.orderPreviewDeliveryCost,
            '\$${preview.deliveryCostMinorUnits}',
          ),
          SizedBox(height: AppHeight.s12),
          Divider(color: ColorManager.textSecondary.withValues(alpha: 0.2)),
          SizedBox(height: AppHeight.s8),
          CustomText(
            text:
                '${AppTranslation.orderPreviewGrandTotal}: \$${preview.grandTotalMinorUnits}',
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s18,
              color: ColorManager.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.p6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: CustomText(
              text: label,
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s12,
                color: ColorManager.descriptionColor,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: CustomText(
              text: value,
              textStyle: getSemiBoldStyle(
                fontSize: AppFontSize.s12,
                color: ColorManager.productNameColor,
              ),
              maxLines: 4,
            ),
          ),
        ],
      ),
    );
  }
}

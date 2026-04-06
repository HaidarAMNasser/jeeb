import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Shows meal prep as a fixed value from the API (minutes), e.g. **46 min** — no countdown.
class DeliveryOrderMealPrepCountdown extends StatelessWidget {
  final String orderId;
  final int? preparationMinutes;

  /// Horizontal: label + value on one row.
  final bool compact;

  const DeliveryOrderMealPrepCountdown({
    super.key,
    required this.orderId,
    this.preparationMinutes,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final mins = preparationMinutes;
    if (mins == null || mins <= 0) return const SizedBox.shrink();

    final value = CustomText(
      text: AppTranslation.preparationMinutesLabel(mins),
      textStyle: getSemiBoldStyle(
        fontSize: AppFontSize.s14,
        color: ColorManager.primary,
      ),
    );

    final label = CustomText(
      text: AppTranslation.preparationTime,
      textStyle: getRegularStyle(
        fontSize: AppFontSize.s10,
        color: ColorManager.textSecondary,
      ),
    );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          SizedBox(width: AppWidth.s8),
          Flexible(child: value),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        SizedBox(height: AppHeight.s4),
        value,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Reusable date select field that opens Flutter's date picker.
/// Use [initialValue] for edit mode; [onDateSelected] is called when user picks a date.
/// When [isDisabled] is not null and true, the field is read-only (no picker, greyed out).
/// UI matches app color palette.
class CustomDateSelect extends StatelessWidget {
  final String? title;
  final DateTime? initialValue;
  final ValueChanged<DateTime?> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hintText;
  /// When not null and true, the field is disabled (read-only, no tap).
  final bool? isDisabled;

  const CustomDateSelect({
    super.key,
    this.title,
    this.initialValue,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.hintText,
    this.isDisabled,
  });

  Future<void> _openDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final first = firstDate ?? now.subtract(const Duration(days: 365));
    final last = lastDate ?? now.add(const Duration(days: 365 * 2));
    final initial = initialValue ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorManager.primary,
              onPrimary: ColorManager.defaultWhite,
              surface: ColorManager.surface,
              onSurface: ColorManager.textDarkColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = initialValue;
    final disabled = isDisabled == true;
    final displayText = value != null
        ? '${value.day}/${value.month}/${value.year}'
        : (hintText ?? AppTranslation.selectDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          CustomText(
            text: title!,
            textStyle: getMediumStyle(
              fontSize: AppFontSize.s15,
              color: ColorManager.defaultWhite,
            ),
          ),
          SizedBox(height: AppHeight.s8),
        ],
        InkWell(
          onTap: disabled ? null : () => _openDatePicker(context),
          borderRadius: BorderRadius.circular(AppRadius.r18),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.p16,
              vertical: AppHeight.s16,
            ),
            decoration: BoxDecoration(
              color: ColorManager.defaultWhite,
              borderRadius: BorderRadius.circular(AppRadius.r18),
              border: Border.all(
                color: ColorManager.borderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: displayText,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s14,
                      color: value != null
                          ? ColorManager.productNameColor
                          : ColorManager.descriptionColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: AppSize.s20,
                  color:  ColorManager.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

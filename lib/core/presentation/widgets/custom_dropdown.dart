import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';


class CustomDropdown<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;

  const CustomDropdown({
    super.key,
    required this.title,
    this.value,
    required this.items,
    this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    // final isRTL = context.locale.languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          text: title,
          textStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s16,
            color: ColorManager.defaultWhite,
          ),
        ),
        SizedBox(height: AppHeight.s8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.borderColor),
            ),
            hintStyle: getRegularStyle(
              color: ColorManager.descriptionColor,
              fontSize: AppFontSize.s13,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppPadding.p16,
              vertical: AppHeight.s16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.borderColor),
            ),
            filled: true,
            fillColor: ColorManager.defaultWhite,
          ),
          style: getRegularStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.productNameColor,
          ),
          dropdownColor: ColorManager.defaultWhite,
          icon: Icon(
            Icons.arrow_drop_down,
            color: ColorManager.descriptionColor,
          ),
          isExpanded: true,
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class CustomTextField extends StatelessWidget {
  final String? title;
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final Color? filledColor;
  final bool? obscureText;
  const CustomTextField({
    super.key,
    this.title,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.filledColor,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          CustomText(
            text: title!,
            textStyle: getMediumStyle(
              fontSize: AppFontSize.s15,
              color: ColorManager.defaultWhite,
            ),
          ),
        SizedBox(height: AppHeight.s8),
        TextField(
          keyboardType: keyboardType,
          obscureText: obscureText ?? false,
          textDirection: textDirection,
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.primary),
            ),
            hintStyle: getRegularStyle(
              color: ColorManager.descriptionColor,
              fontSize: AppFontSize.s13,
            ),
            hintTextDirection: textDirection,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppPadding.p16,
              vertical: AppHeight.s16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.primary),
            ),
            filled: true,
            fillColor: filledColor ?? ColorManager.transparent,
          ),
          style: getRegularStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.defaultWhite,
          ),
        ),
      ],
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;

  const CustomDropdownField({
    required this.label,
    required this.items,
    this.onChanged,
    required UniqueKey key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        CustomText(text: label),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.r),
              borderSide: BorderSide(color: ColorManager.primaryDark),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

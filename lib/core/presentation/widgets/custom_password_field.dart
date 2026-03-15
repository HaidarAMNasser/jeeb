import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class CustomPasswordField extends StatefulWidget {
  final String title;
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const CustomPasswordField({
    super.key,
    required this.title,
    required this.hintText,
    this.controller,
    this.onChanged,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          text: widget.title,
          textStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s16,
            color: ColorManager.defaultWhite,
          ),
        ),
        SizedBox(height: AppHeight.s8),
        TextField(
          textDirection: textDirection,
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
          controller: widget.controller,
          onChanged: widget.onChanged,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: widget.hintText,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.borderColor),
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
              borderSide: BorderSide(color: ColorManager.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.borderColor),
            ),
            filled: true,
            fillColor: ColorManager.defaultWhite,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: ColorManager.descriptionColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          style: getRegularStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.productNameColor,
          ),
        ),
      ],
    );
  }
}


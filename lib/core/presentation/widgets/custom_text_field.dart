import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:easy_localization/easy_localization.dart' as easy_localization;
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class CustomTextField extends StatefulWidget {
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
  /// When true with [obscureText] true, shows an eye toggle to show/hide the value.
  final bool showObscureTextToggle;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Color? textColor;
  final Color? hintColor;

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
    this.showObscureTextToggle = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textColor,
    this.hintColor,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText ?? false;
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showObscureTextToggle &&
        oldWidget.showObscureTextToggle != widget.showObscureTextToggle) {
      _obscure = widget.obscureText ?? false;
    }
  }

  bool get _useToggle =>
      widget.showObscureTextToggle && (widget.obscureText ?? false);

  bool get _effectiveObscure => _useToggle ? _obscure : (widget.obscureText ?? false);

  @override
  Widget build(BuildContext context) {
    final isRTL = context.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    final visibilitySuffix = _useToggle
        ? IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: ColorManager.descriptionColor,
            ),
            onPressed: () {
              setState(() {
                _obscure = !_obscure;
              });
            },
          )
        : null;

    final Widget? combinedSuffix = visibilitySuffix != null && widget.suffixIcon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [widget.suffixIcon!, visibilitySuffix],
          )
        : visibilitySuffix ?? widget.suffixIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          CustomText(
            text: widget.title!,
            textStyle: getMediumStyle(
              fontSize: AppFontSize.s15,
              color: ColorManager.defaultWhite,
            ),
          ),
        SizedBox(height: AppHeight.s8),
        TextField(
          keyboardType: widget.keyboardType,
          obscureText: _effectiveObscure,
          textDirection: textDirection,
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
          controller: widget.controller,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          cursorColor: ColorManager.primary,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: combinedSuffix,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.r18),
              borderSide: BorderSide(color: ColorManager.primary),
            ),
            hintStyle: getRegularStyle(
              color: widget.hintColor ?? ColorManager.descriptionColor,
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
            fillColor: widget.filledColor ?? ColorManager.defaultWhite,
          ),
          style: getRegularStyle(
            fontSize: AppFontSize.s14,
            color: widget.textColor ?? ColorManager.productNameColor,
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

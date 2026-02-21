import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const CustomTextField({
    required this.hintText,
    this.controller,
    this.onChanged,
    required UniqueKey key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      textDirection: TextDirection.rtl,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        hintStyle: getRegularStyle(color: Colors.grey, fontSize: AppFontSize.s13),
        hintTextDirection: TextDirection.rtl,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.r),
            borderSide: BorderSide(color: ColorManager.borderColor)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24.r),
          borderSide: BorderSide(color: ColorManager.primaryDark),
        ),
      ),
      style: getRegularStyle(fontSize: AppFontSize.s14),
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
        CustomText(
          text: label,
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<T>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
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

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textcolor;
  final double? elevation;
  const CustomButton(
      {required this.text,
      required this.onPressed,
      this.elevation,
      required this.color,
      required this.textcolor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: this.elevation ?? 0,
        backgroundColor: color,
        foregroundColor: textcolor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        textStyle: getRegularStyle(
          color: Colors.white,
          fontSize: AppFontSize.s16,
        ),
      ),
      child: CustomText(text: text),
    );
  }
}

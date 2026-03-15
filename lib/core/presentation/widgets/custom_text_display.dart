// import 'package:flutter/material.dart';
// import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
// import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
// import 'package:jeeb_admin/core/presentation/theme/styles_manager.dart';
// import 'package:jeeb_admin/core/presentation/widgets/text_widget.dart';

// class CustomTextDisplay extends StatelessWidget {
//   final String text;
//   final double? fontSize;
//   final Color? color;
//   final FontWeight? fontWeight;
//   final TextAlign? textAlign;
//   final int? maxLines;
//   final TextOverflow? overflow;

//   const CustomTextDisplay({
//     super.key,
//     required this.text,
//     this.fontSize,
//     this.color,
//     this.fontWeight,
//     this.textAlign,
//     this.maxLines,
//     this.overflow,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CustomText(
//       text: text,
//       textStyle: getRegularStyle(
//         fontSize: fontSize ?? AppFontSize.s14,
//         color: color ?? ColorManager.textColor,
//       ),
//       textAlign: textAlign ?? TextAlign.start,
//       maxLines: maxLines,
//       textOverflow: overflow,
//     );
//   }
// }

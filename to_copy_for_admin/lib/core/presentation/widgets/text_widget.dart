import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final int? maxLines;
  final TextOverflow? textOverflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  const CustomText(
      {super.key,
      required this.text,
      this.textStyle,
      this.maxLines,
      this.softWrap,
      this.textAlign,
      this.textOverflow});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: textStyle,
        maxLines: maxLines,
        softWrap:softWrap?? true,
        overflow: textOverflow,
        textAlign: textAlign);
  }
}

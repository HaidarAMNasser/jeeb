import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Single line of text that scrolls horizontally when it overflows (e.g. long names).
class HorizontalScrollableText extends StatelessWidget {
  const HorizontalScrollableText({
    super.key,
    required this.text,
    required this.textStyle,
    this.height,
  });

  final String text;
  final TextStyle textStyle;

  /// Fixed viewport height for the scroll area. Defaults to [AppHeight.s24].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? AppHeight.s24,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CustomText(
          text: text,
          textStyle: textStyle,
          maxLines: 1,
        ),
      ),
    );
  }
}

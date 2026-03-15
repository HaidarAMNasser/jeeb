import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class AvatarImagePicker extends StatelessWidget {
  final String? imagePath;
  final String? fallbackInitial;
  final VoidCallback? onTap;
  final double radius;

  const AvatarImagePicker({
    super.key,
    this.imagePath,
    this.fallbackInitial,
    this.onTap,
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: ColorManager.defaultWhite,
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(imagePath!),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
    }
    if (fallbackInitial != null && fallbackInitial!.isNotEmpty) {
      return CustomText(
        textAlign: TextAlign.center,
        text: fallbackInitial!,
        textStyle: getBoldStyle(
          fontSize: AppFontSize.s24,
          color: ColorManager.titlesColor,
        ),
      );
    }
    return Icon(
      Icons.add_a_photo,
      size: AppSize.s30,
      color: ColorManager.titlesColor,
    );
  }
}


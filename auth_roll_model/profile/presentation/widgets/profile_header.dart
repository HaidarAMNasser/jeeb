import 'package:flutter/material.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_display.dart';
import '../../../login/domain/entities/user_entity.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity user;

  const ProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: ColorManager.primary,
            child: CustomTextDisplay(
              text: user.firstName[0].toUpperCase(),
              fontSize: AppFontSize.s24,
              color: ColorManager.titlesColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppHeight.s16),
          CustomTextDisplay(
            text: user.fullName,
            fontSize: AppFontSize.s20,
            color: ColorManager.titlesColor,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: AppHeight.s8),
          CustomTextDisplay(
            text: user.email,
            fontSize: AppFontSize.s14,
            color: ColorManager.textColor,
          ),
        ],
      ),
    );
  }
}


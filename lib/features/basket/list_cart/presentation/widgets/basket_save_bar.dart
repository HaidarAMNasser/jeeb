import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class BasketSaveBar extends StatelessWidget {
  final VoidCallback onSave;

  const BasketSaveBar({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppPadding.p16,
        0,
        AppPadding.p16,
        AppPadding.p16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppHeight.s56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.primary,
            foregroundColor: ColorManager.defaultWhite,
          ),
          onPressed: onSave,
          child: CustomText(
            text: AppTranslation.save,
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s16,
              color: ColorManager.defaultWhite,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class DeliveryRouteLegende extends StatelessWidget {
  const DeliveryRouteLegende({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppPadding.p16,
          0,
          AppPadding.p16,
          AppPadding.p8,
        ),
        child: CustomText(
          text: AppTranslation.deliveryRouteLegendWalked,
          textStyle: getRegularStyle(
            fontSize: AppFontSize.s11,
            color: ColorManager.textSecondary,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

class OrderPeopleCard extends StatelessWidget {
  final int numberOfPeople;

  const OrderPeopleCard({super.key, required this.numberOfPeople});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.defaultWhite,
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Row(
          children: [
            Icon(
              Icons.people,
              color: ColorManager.primary,
              size: AppSize.s20,
            ),
            SizedBox(width: AppWidth.s12),
            CustomText(
              text: '${AppTranslation.numberOfPeople}: $numberOfPeople',
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.productNameColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


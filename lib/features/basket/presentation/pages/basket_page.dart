import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslation.basket),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: AppSize.s100,
              color: ColorManager.textSecondary.withOpacity(0.5),
            ),
            SizedBox(height: AppHeight.s16),
            Text(
              AppTranslation.basketIsEmpty ?? 'Basket is Empty',
              style: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

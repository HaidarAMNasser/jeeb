import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

class DeliveryHomePage extends StatelessWidget {
  const DeliveryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslation.home),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: AppSize.s100,
              color: ColorManager.primary.withOpacity(0.5),
            ),
            SizedBox(height: AppHeight.s16),
            Text(
              'Welcome, Delivery Partner!',
              style: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.textSecondary,
              ),
            ),
            SizedBox(height: AppHeight.s8),
            Text(
              'Waiting for new orders...',
              style: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

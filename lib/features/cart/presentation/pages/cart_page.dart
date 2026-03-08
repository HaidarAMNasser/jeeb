import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppPadding.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Cart',
                style: getBoldStyle(
                  fontSize: AppFontSize.s24,
                  color: ColorManager.primary,
                ),
              ),
              SizedBox(height: AppHeight.s20),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: ColorManager.textSecondary,
                      ),
                      SizedBox(height: AppHeight.s16),
                      Text(
                        'Your cart is empty',
                        style: getRegularStyle(
                          fontSize: AppFontSize.s16,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppHeight.s8),
                      Text(
                        'Add items to get started',
                        style: getRegularStyle(
                          fontSize: AppFontSize.s14,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

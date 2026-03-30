import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

class DeliveryOrdersEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const DeliveryOrdersEmptyState({
    super.key,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppSize.s70,
            color: ColorManager.textSecondary.withOpacity(0.3),
          ),
          SizedBox(height: AppHeight.s16),
          Text(
            message,
            style: getMediumStyle(
              fontSize: AppFontSize.s16,
              color: ColorManager.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

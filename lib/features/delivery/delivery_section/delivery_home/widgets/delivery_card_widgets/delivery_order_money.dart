import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';

/// Readable money display: separates dollars / cents for hierarchy (cards & line items).
class OrderMoneyText extends StatelessWidget {
  final int minor;
  final OrderMoneyStyle style;

  const OrderMoneyText({
    super.key,
    required this.minor,
    this.style = OrderMoneyStyle.inline,
  });

  int get _dollars => minor.abs() ~/ 100;
  int get _cents => minor.abs() % 100;

  @override
  Widget build(BuildContext context) {
    final sign = minor < 0 ? '-' : '';
    final cs = _cents.toString().padLeft(2, '0');

    switch (style) {
      case OrderMoneyStyle.inline:
        return RichText(
          text: TextSpan(
            style: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.titlesColor,
            ),
            children: [
              TextSpan(
                text: sign,
                style: getSemiBoldStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.titlesColor.withOpacity(0.88),
                ),
              ),
              TextSpan(
                text: '\$',
                style: getMediumStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.textSecondary,
                ),
              ),
              TextSpan(
                text: '$_dollars',
                style: getSemiBoldStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.titlesColor.withOpacity(0.92),
                ),
              ),
              TextSpan(
                text: '.$cs',
                style: getMediumStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.textSecondary,
                ),
              ),
            ],
          ),
        );
      case OrderMoneyStyle.capstone:
        return RichText(
          textAlign: TextAlign.end,
          text: TextSpan(
            style: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.titlesColor,
            ),
            children: [
              TextSpan(
                text: sign,
                style: getBoldStyle(
                  fontSize: AppFontSize.s22,
                  color: ColorManager.titlesColor,
                ),
              ),
              TextSpan(
                text: '\$',
                style: getSemiBoldStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.primary.withOpacity(0.85),
                ),
              ),
              TextSpan(
                text: '$_dollars',
                style: getBoldStyle(
                  fontSize: AppFontSize.s26,
                  color: ColorManager.titlesColor,
                ),
              ),
              TextSpan(
                text: '.$cs',
                style: getBoldStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.primary,
                ),
              ),
            ],
          ),
        );
    }
  }
}

enum OrderMoneyStyle { inline, capstone }

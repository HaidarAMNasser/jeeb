import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Status caption pill below the wave rail (icon + text).
/// Optional [subtitle] renders under [caption] inside the same card (e.g. tracking hints).
class OrderBadgeWidget extends StatelessWidget {
  const OrderBadgeWidget({
    super.key,
    required this.caption,
    required this.accentColor,
    this.subtitle,
    this.enableSmallBadge = false,
    this.normalDesign = false,
    this.width,
    this.icon,
    this.onTap,
  });

  final String caption;
  /// Shown under [caption] in the same badge; slightly smaller, readable body text.
  final String? subtitle;
  final Color accentColor;
  final IconData? icon;
  final bool normalDesign;
  final double? width;
  final bool enableSmallBadge;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: enableSmallBadge ? width : null,
        padding: EdgeInsets.symmetric(
          horizontal: enableSmallBadge ? AppPadding.p10 : AppPadding.p18,
          vertical: enableSmallBadge
              ? AppPadding.p8
              : (subtitle != null && subtitle!.trim().isNotEmpty
                    ? AppPadding.p16
                    : AppPadding.p14),
        ),
        decoration: BoxDecoration(
          color: normalDesign ? accentColor : accentColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.r20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.55),
            width: 2,
          ),
          boxShadow: normalDesign
              ? null
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSize.s28, color: accentColor),
              SizedBox(width: AppWidth.s12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: caption,
                    textStyle: getBoldStyle(
                      fontSize: enableSmallBadge
                          ? AppFontSize.s12
                          : AppFontSize.s18,
                      color: const Color(0xFFFFF5EC),
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.start,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    SizedBox(height: AppHeight.s8),
                    CustomText(
                      text: subtitle!.trim(),
                      textStyle: getRegularStyle(
                        fontSize: enableSmallBadge
                            ? AppFontSize.s11
                            : AppFontSize.s14,
                        color: const Color(0xFFE8E2DC),
                      ),
                      maxLines: 5,
                      textAlign: TextAlign.start,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

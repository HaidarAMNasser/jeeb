import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// Client-only: single minimal row to call support (separate from driver card).
class OrderClientSupportPhoneRow extends StatelessWidget {
  const OrderClientSupportPhoneRow({
    super.key,
    required this.supportPhone,
    this.darkBackground = false,
  });

  final String supportPhone;
  final bool darkBackground;

  static String _telPath(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-.()]'), '');

  Future<void> _call(BuildContext context) async {
    final path = _telPath(supportPhone.trim());
    if (path.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: path);
    try {
      var launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open phone app')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = supportPhone.trim();
    if (s.isEmpty) return const SizedBox.shrink();

    final border = darkBackground
        ? Colors.white.withValues(alpha: 0.08)
        : ColorManager.descriptionColor.withValues(alpha: 0.22);
    final labelColor = darkBackground
        ? const Color(0xFF9E9893)
        : ColorManager.descriptionColor;
    final valueColor = darkBackground
        ? const Color(0xFFE8E4E0)
        : ColorManager.productNameColor;
    final iconColor =
        darkBackground ? ColorManager.primary : ColorManager.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _call(context),
        borderRadius: BorderRadius.circular(AppRadius.r10),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p12,
            vertical: AppPadding.p10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r10),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(Icons.support_agent_outlined, size: 20, color: iconColor),
              SizedBox(width: AppPadding.p10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: AppTranslation.orderStatusSupportNumberLabel,
                      textStyle: getMediumStyle(
                        fontSize: AppFontSize.s11,
                        color: labelColor,
                      ),
                    ),
                    SizedBox(height: AppHeight.s3),
                    CustomText(
                      text: s,
                      textStyle: getSemiBoldStyle(
                        fontSize: AppFontSize.s14,
                        color: valueColor,
                      ),
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.phone_outlined, size: 20, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

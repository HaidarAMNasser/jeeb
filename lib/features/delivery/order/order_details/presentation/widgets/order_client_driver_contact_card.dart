import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// Client order details: minimal card with driver name and optional phone.
class OrderClientDriverContactCard extends StatelessWidget {
  const OrderClientDriverContactCard({
    super.key,
    required this.driverName,
    this.driverPhone,
  });

  final String driverName;
  final String? driverPhone;

  static String _initials(String name) {
    final s = name.trim();
    if (s.isEmpty) return '';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      final a = parts[0].isNotEmpty ? parts[0][0] : '';
      final b = parts[1].isNotEmpty ? parts[1][0] : '';
      return ('$a$b').toUpperCase();
    }
    if (s.length >= 2) return s.substring(0, 2).toUpperCase();
    return s[0].toUpperCase();
  }

  static String _telPath(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-.()]'), '');

  Future<void> _callPhone(BuildContext context, String raw) async {
    final path = _telPath(raw.trim());
    if (path.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: path);
    try {
      if (await canLaunchUrl(uri) && context.mounted) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = driverName.trim();
    final displayName =
        name.isNotEmpty ? name : AppTranslation.deliveryMan;
    final initials = _initials(name.isNotEmpty ? name : displayName);
    final phone = driverPhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: const Color(0xFF343230),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(
          color: ColorManager.textSecondary.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.primary.withValues(alpha: 0.2),
            ),
            alignment: Alignment.center,
            child: initials.isEmpty
                ? Icon(
                    Icons.delivery_dining_outlined,
                    size: 22,
                    color: ColorManager.primary,
                  )
                : Text(
                    initials,
                    style: getBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: const Color(0xFFFFF5EC),
                    ),
                  ),
          ),
          SizedBox(width: AppPadding.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: AppTranslation.orderStatusDriverCardTitle,
                  textStyle: getMediumStyle(
                    fontSize: AppFontSize.s10,
                    color: ColorManager.textPrimary,
                  ),
                ),
                SizedBox(height: AppHeight.s3),
                CustomText(
                  text: displayName,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s15,
                    color: ColorManager.titlesColor,
                  ),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
                if (hasPhone) ...[
                  SizedBox(height: AppHeight.s8),
                  InkWell(
                    onTap: () => _callPhone(context, phone),
                    borderRadius: BorderRadius.circular(AppRadius.r6),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppPadding.p4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: ColorManager.primary,
                          ),
                          SizedBox(width: AppPadding.p6),
                          Expanded(
                            child: CustomText(
                              text: phone,
                              textStyle: getMediumStyle(
                                fontSize: AppFontSize.s13,
                                color: ColorManager.primary,
                              ),
                              maxLines: 1,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

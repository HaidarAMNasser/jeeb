import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// Refined driver strip for the dark order-tracking screen: name, phone, tap-to-call.
class OrderStatusDriverContactCard extends StatelessWidget {
  const OrderStatusDriverContactCard({
    super.key,
    required this.driverName,
    required this.driverPhone,
  });

  final String? driverName;
  final String? driverPhone;

  static String _initials(String? name) {
    final s = name?.trim();
    if (s == null || s.isEmpty) return '';
    final parts = s
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      final a = parts[0].isNotEmpty ? parts[0][0] : '';
      final b = parts[1].isNotEmpty ? parts[1][0] : '';
      return ('$a$b').toUpperCase();
    }
    if (s.length >= 2) return s.substring(0, 2).toUpperCase();
    return s[0].toUpperCase();
  }

  static String _telPath(String raw) {
    return raw.replaceAll(RegExp(r'[\s\-.()]'), '');
  }

  Future<void> _launchCall(BuildContext context) async {
    final phone = driverPhone?.trim() ?? '';
    if (phone.isEmpty) return;
    final path = _telPath(phone);
    if (path.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: path);
    try {
      final ok = await canLaunchUrl(uri);
      if (ok && context.mounted) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = driverName?.trim() ?? '';
    final phone = driverPhone?.trim() ?? '';
    final displayName =
        name.isNotEmpty ? name : AppTranslation.deliveryMan;
    final initials = _initials(name.isNotEmpty ? name : displayName);
    final canCall = phone.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary.withValues(alpha: 0.22),
            const Color(0xFF2C2A28).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: ColorManager.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: ColorManager.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorManager.primary,
                  ColorManager.primary.withValues(alpha: 0.75),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: ColorManager.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: initials.isEmpty
                ? Icon(
                    Icons.delivery_dining_rounded,
                    color: const Color(0xFFFFF5EC),
                    size: AppSize.s28,
                  )
                : Text(
                    initials,
                    style: getBoldStyle(
                      fontSize: AppFontSize.s18,
                      color: const Color(0xFFFFF5EC),
                    ),
                  ),
          ),
          SizedBox(width: AppPadding.p14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: AppTranslation.orderStatusDriverCardTitle,
                  textStyle: getMediumStyle(
                    fontSize: AppFontSize.s11,
                    color: const Color(0xFFC9C2BC),
                  ),
                ),
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: displayName,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: const Color(0xFFFFF5EC),
                  ),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty) ...[
                  SizedBox(height: AppHeight.s4),
                  CustomText(
                    text: phone,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s13,
                      color: const Color(0xFFE8E2DC),
                    ),
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (canCall) ...[
            SizedBox(width: AppPadding.p8),
            Tooltip(
              message: AppTranslation.orderStatusDriverCall,
              child: Material(
                color: const Color(0xFFFFF5EC).withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _launchCall(context),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      Icons.phone_rounded,
                      color: ColorManager.primary,
                      size: AppSize.s24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

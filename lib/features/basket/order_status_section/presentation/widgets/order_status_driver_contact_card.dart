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
    this.supportPhone,
  });

  final String? driverName;
  final String? driverPhone;
  final String? supportPhone;

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

  Future<void> _launchSupportCall(BuildContext context) async {
    final phone = supportPhone?.trim() ?? '';
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
    final displayName =
        name.isNotEmpty ? name : AppTranslation.deliveryMan;
    final initials = _initials(name.isNotEmpty ? name : displayName);
    final support = supportPhone?.trim() ?? '';
    final canCallSupport = support.isNotEmpty;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                  ],
                ),
              ),
            ],
          ),
          if (canCallSupport) ...[
            SizedBox(height: AppHeight.s12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.p12,
                vertical: AppPadding.p10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border: Border.all(
                  color: const Color(0xFFFFC481).withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    color: const Color(0xFFFFC481),
                    size: AppSize.s20,
                  ),
                  SizedBox(width: AppPadding.p10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          text: AppTranslation.orderStatusSupportNumberLabel,
                          textStyle: getSemiBoldStyle(
                            fontSize: AppFontSize.s12,
                            color: const Color(0xFFFFD8A9),
                          ),
                        ),
                        SizedBox(height: AppHeight.s4),
                        CustomText(
                          text: support,
                          textStyle: getRegularStyle(
                            fontSize: AppFontSize.s13,
                            color: const Color(0xFFFFF5EC),
                          ),
                          maxLines: 1,
                          textOverflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppPadding.p8),
                  Tooltip(
                    message: AppTranslation.orderStatusSupportCall,
                    child: Material(
                      color: const Color(0xFFFFF5EC).withValues(alpha: 0.1),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _launchSupportCall(context),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.phone_forwarded_rounded,
                            color: const Color(0xFFFFC481),
                            size: AppSize.s22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

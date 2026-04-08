import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_order_common.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryOrderHeader extends StatelessWidget {
  final String recipientName;
  final String recipientAddress;
  final int totalPrice;
  final bool showPriceTag;
  final String? customerPhone;
  final String? driverPhone;

  const DeliveryOrderHeader({
    super.key,
    required this.recipientName,
    required this.recipientAddress,
    required this.totalPrice,
    this.showPriceTag = true,
    this.customerPhone,
    this.driverPhone,
  });

  @override
  Widget build(BuildContext context) {
    final c = customerPhone?.trim();
    final d = driverPhone?.trim();
    final hasC = c != null && c.isNotEmpty;
    final hasD = d != null && d.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildAvatarIcon(Icons.person, ColorManager.primary),
        SizedBox(width: AppWidth.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: recipientName,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s18,
                  color: ColorManager.titlesColor,
                ),
              ),
              if (recipientAddress.isNotEmpty)
                CustomText(
                  text: recipientAddress,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.defaultWhite,
                  ),
                ),
              if (hasC || hasD) ...[
                SizedBox(height: AppHeight.s8),
                _CustomerDriverPhonesInlineRow(
                  customerPhone: hasC ? c : null,
                  driverPhone: hasD ? d : null,
                ),
              ],
            ],
          ),
        ),
        if (showPriceTag) buildPriceTag(totalPrice),
      ],
    );
  }
}

/// One horizontal row: client phone | driver phone — scrolls if long; no flex shrink.
class _CustomerDriverPhonesInlineRow extends StatelessWidget {
  const _CustomerDriverPhonesInlineRow({
    required this.customerPhone,
    required this.driverPhone,
  });

  final String? customerPhone;
  final String? driverPhone;

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppTranslation.phoneCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (customerPhone != null) ...[
            Icon(
              Icons.person_outline_rounded,
              size: AppSize.s16,
              color: ColorManager.primary,
            ),
            SizedBox(width: AppWidth.s4),
            SelectableText(
              customerPhone!,
              style: getSemiBoldStyle(
                fontSize: AppFontSize.s12,
                color: ColorManager.primary,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              icon: Icon(
                Icons.call_rounded,
                size: AppSize.s18,
                color: ColorManager.primary,
              ),
              tooltip: AppTranslation.call,
              onPressed: () => launchUrl(Uri.parse('tel:$customerPhone')),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              icon: Icon(
                Icons.copy_rounded,
                size: AppSize.s16,
                color: ColorManager.primary,
              ),
              tooltip: AppTranslation.copyPhone,
              onPressed: () => _copy(context, customerPhone!),
            ),
          ],
          if (customerPhone != null && driverPhone != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppPadding.p6),
              child: Text(
                '|',
                style: getRegularStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.textSecondary,
                ),
              ),
            ),
          if (driverPhone != null) ...[
            Icon(
              Icons.delivery_dining_rounded,
              size: AppSize.s16,
              color: ColorManager.primary,
            ),
            SizedBox(width: AppWidth.s4),
            SelectableText(
              driverPhone!,
              style: getSemiBoldStyle(
                fontSize: AppFontSize.s12,
                color: ColorManager.primary,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              icon: Icon(
                Icons.call_rounded,
                size: AppSize.s18,
                color: ColorManager.primary,
              ),
              tooltip: AppTranslation.call,
              onPressed: () => launchUrl(Uri.parse('tel:$driverPhone')),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              icon: Icon(
                Icons.copy_rounded,
                size: AppSize.s16,
                color: ColorManager.primary,
              ),
              tooltip: AppTranslation.copyPhone,
              onPressed: () => _copy(context, driverPhone!),
            ),
          ],
        ],
      ),
    );
  }
}

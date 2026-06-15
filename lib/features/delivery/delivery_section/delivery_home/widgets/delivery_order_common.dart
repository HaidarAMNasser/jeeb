import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:url_launcher/url_launcher.dart';

Widget buildAvatarIcon(IconData icon, Color color) {
  return Container(
    padding: EdgeInsets.all(AppPadding.p8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: AppSize.s20, color: color),
  );
}

Widget buildPriceTag(int price) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppPadding.p12,
      vertical: AppPadding.p6,
    ),
    decoration: BoxDecoration(
      color: ColorManager.primary,
      borderRadius: BorderRadius.circular(AppSize.s12),
      boxShadow: [
        BoxShadow(
          color: ColorManager.primary.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: CustomText(
      text: 'SYP ${(price / 100).toStringAsFixed(2)}',
      textStyle: getBoldStyle(fontSize: AppFontSize.s14, color: Colors.white),
    ),
  );
}

/// Phone row: tap to call, copy icon, [SelectableText] for selection/copy.
class CopyablePhoneRow extends StatelessWidget {
  const CopyablePhoneRow({super.key, required this.phone});

  final String phone;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppTranslation.phoneCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.phone_in_talk_outlined,
          size: AppSize.s16,
          color: ColorManager.primary,
        ),
        SizedBox(width: AppWidth.s8),
        Expanded(
          child: SelectableText(
            phone,
            style: getSemiBoldStyle(
              fontSize: AppFontSize.s13,
              color: ColorManager.primary,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(Icons.call_rounded, size: AppSize.s20, color: ColorManager.primary),
          tooltip: AppTranslation.call,
          onPressed: () => launchUrl(Uri.parse('tel:$phone')),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(Icons.copy_rounded, size: AppSize.s18, color: ColorManager.primary),
          tooltip: AppTranslation.copyPhone,
          onPressed: () => _copy(context),
        ),
      ],
    );
  }
}


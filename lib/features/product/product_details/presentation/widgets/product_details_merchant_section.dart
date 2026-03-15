import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class ProductDetailsMerchantSection extends StatelessWidget {
  final String? merchantName;
  final String? merchantAddress;
  final String? merchantPhone;

  const ProductDetailsMerchantSection({
    super.key,
    this.merchantName,
    this.merchantAddress,
    this.merchantPhone,
  });

  bool get _hasAny =>
      (merchantName != null && merchantName!.isNotEmpty) ||
      (merchantAddress != null && merchantAddress!.isNotEmpty) ||
      (merchantPhone != null && merchantPhone!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: AppTranslation.merchant,
          textStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s16,
            color: ColorManager.defaultWhite,
          ),
        ),
        SizedBox(height: AppHeight.s8),
        Container(
          padding: EdgeInsets.all(AppPadding.p12),
          decoration: BoxDecoration(
            color: ColorManager.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: ColorManager.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (merchantName != null && merchantName!.isNotEmpty)
                _InfoRow(icon: Icons.store, label: merchantName!),
              if (merchantAddress != null && merchantAddress!.isNotEmpty)
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: merchantAddress!),
              if (merchantPhone != null && merchantPhone!.isNotEmpty)
                _InfoRow(icon: Icons.phone_outlined, label: merchantPhone!),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppHeight.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ColorManager.primary),
          SizedBox(width: AppPadding.p8),
          Expanded(
            child: CustomText(
              text: label,
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

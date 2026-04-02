import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class DeliveryMerchantPhoneRow extends StatelessWidget {
  final String phone;

  const DeliveryMerchantPhoneRow({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.phone_android,
          size: AppSize.s16,
          color: ColorManager.textSecondary,
        ),
        SizedBox(width: AppWidth.s8),
        CustomText(
          text: phone,
          textStyle: getMediumStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.titlesColor,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            Icons.copy_all_outlined,
            size: AppSize.s20,
            color: ColorManager.primary,
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: phone));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone copied to clipboard')),
            );
          },
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}


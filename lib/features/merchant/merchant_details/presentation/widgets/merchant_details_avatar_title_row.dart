import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Large circular avatar + name and email (details header).
class MerchantDetailsAvatarTitleRow extends StatelessWidget {
  const MerchantDetailsAvatarTitleRow({
    super.key,
    required this.name,
    required this.email,
    this.imageUrl,
  });

  final String name;
  final String email;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.r100)),
            child: Container(
              width: AppWidth.s100,
              height: AppHeight.s100,
              color: ColorManager.background,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
            ),
          )
        else
          _placeholder(),
        SizedBox(width: AppWidth.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: name,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s20,
                  color: ColorManager.productNameColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: AppWidth.s100,
      height: AppHeight.s100,
      decoration: BoxDecoration(
        color: ColorManager.background,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.store, color: ColorManager.primary, size: AppSize.s40),
    );
  }
}

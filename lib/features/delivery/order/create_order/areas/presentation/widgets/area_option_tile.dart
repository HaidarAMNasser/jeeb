import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/domain/entities/area_entity.dart';

class AreaOptionTile extends StatelessWidget {
  final AreaEntity area;
  final bool isSelected;
  final VoidCallback onTap;

  const AreaOptionTile({
    super.key,
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  String get _priceText {
    final display = (area.displayPrice / 100).toStringAsFixed(2);
    return ' SYP $display';
  }

  bool get _hasDescription =>
      area.description != null && area.description!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Container(
        padding: EdgeInsets.all(AppPadding.p16),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorManager.primary.withOpacity(0.1)
              : ColorManager.background,
          border: Border.all(
            color: isSelected
                ? ColorManager.primary
                : ColorManager.borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text: area.name,
                          textStyle: getSemiBoldStyle(
                            fontSize: AppFontSize.s18,
                            color: isSelected
                                ? ColorManager.primary
                                : ColorManager.titlesColor,
                          ),
                        ),
                      ),
                      CustomText(
                        text: _priceText,
                        textStyle: getBoldStyle(
                          fontSize: AppFontSize.s16,
                          color: ColorManager.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_hasDescription) ...[
                    SizedBox(height: AppHeight.s4),
                    CustomText(
                      text: area.description!,
                      textStyle: getRegularStyle(
                        color: ColorManager.descriptionColor,
                      ),
                      maxLines: 2,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: AppWidth.s8),
              Icon(
                Icons.check_circle,
                color: ColorManager.primary,
                size: AppSize.s24,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

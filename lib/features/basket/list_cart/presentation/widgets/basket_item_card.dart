import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';

class BasketItemCard extends StatelessWidget {
  final CartDraftItem item;
  final String Function(int) priceFormatter;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const BasketItemCard({
    super.key,
    required this.item,
    required this.priceFormatter,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppHeight.s12),
      padding: EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: ColorManager.lightPrimary,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: SizedBox(
              width: AppWidth.s66,
              height: AppHeight.s66,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CustomCachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      width: AppWidth.s66,
                      height: AppHeight.s66,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: ColorManager.lightPrimary,
                        borderRadius: BorderRadius.circular(AppRadius.r12),
                        border: Border.all(color: ColorManager.primary),
                      ),
                      child: Icon(
                        Icons.fastfood_outlined,
                        color: ColorManager.textSecondary,
                        size: AppSize.s24,
                      ),
                    ),
            ),
          ),
          SizedBox(width: AppWidth.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: item.productName,
                  textStyle: getBoldStyle(
                    fontSize: AppFontSize.s16,
                    color: ColorManager.productNameColor,
                  ),
                ),
                if ((item.description ?? '').trim().isNotEmpty) ...[
                  SizedBox(height: AppHeight.s4),
                  CustomText(
                    text: item.description!,
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s12,
                      color: ColorManager.textSecondary,
                    ),
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: AppHeight.s5),
                CustomText(
                  text: 'SYP ${priceFormatter(item.totalPrice)}',
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppWidth.s8),
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onIncrease,
                icon: const Icon(Icons.add_circle_outline),
              ),
              CustomText(
                text: '${item.quantity}',
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.productNameColor,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDecrease,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

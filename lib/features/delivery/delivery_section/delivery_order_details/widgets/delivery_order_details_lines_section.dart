import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

String formatOrderMoneyMinor(int minor) =>
    '\$${(minor / 100).toStringAsFixed(2)}';

class DeliveryOrderDetailsLinesSection extends StatelessWidget {
  final List<OrderLineProductEntity> itemLines;
  final List<OrderOfferBundleEntity> offerBundles;
  final List<ProductEntity> fallbackProducts;

  const DeliveryOrderDetailsLinesSection({
    super.key,
    required this.itemLines,
    required this.offerBundles,
    this.fallbackProducts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasStructured =
        offerBundles.isNotEmpty || itemLines.isNotEmpty;

    if (!hasStructured) {
      return _FallbackProductsList(products: fallbackProducts);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (offerBundles.isNotEmpty) ...[
          CustomText(
            text: AppTranslation.orderDetailsOffers,
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.primary,
            ),
          ),
          SizedBox(height: AppHeight.s10),
          ...offerBundles.map(_OfferBundleCard.new),
          if (itemLines.isNotEmpty) SizedBox(height: AppHeight.s16),
        ],
        if (itemLines.isNotEmpty) ...[
          CustomText(
            text: AppTranslation.orderDetailsItems,
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.primary,
            ),
          ),
          SizedBox(height: AppHeight.s10),
          ...itemLines.map((e) => Padding(
                padding: EdgeInsets.only(bottom: AppPadding.p10),
                child: _LineRow(line: e),
              )),
        ],
      ],
    );
  }
}

class _OfferBundleCard extends StatelessWidget {
  final OrderOfferBundleEntity bundle;

  const _OfferBundleCard(this.bundle);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppPadding.p12),
      padding: EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: ColorManager.background,
        borderRadius: BorderRadius.circular(AppSize.s12),
        border: Border.all(color: ColorManager.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: bundle.name.isEmpty
                ? AppTranslation.orderDetailsOffers
                : bundle.name,
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s13,
              color: ColorManager.titlesColor,
            ),
          ),
          if (bundle.description != null &&
              bundle.description!.trim().isNotEmpty) ...[
            SizedBox(height: AppHeight.s4),
            CustomText(
              text: bundle.description!.trim(),
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s11,
                color: ColorManager.textSecondary,
              ),
              maxLines: 3,
              textOverflow: TextOverflow.ellipsis,
            ),
          ],
          if (bundle.subtotalMinor != null) ...[
            SizedBox(height: AppHeight.s8),
            _tinyRow(
              AppTranslation.orderOfferSubtotal,
              formatOrderMoneyMinor(bundle.subtotalMinor!),
            ),
          ],
          if (bundle.offerDiscountMinor != null &&
              bundle.offerDiscountMinor! > 0) ...[
            SizedBox(height: AppHeight.s4),
            _tinyRow(
              AppTranslation.orderOfferDiscount,
              '- ${formatOrderMoneyMinor(bundle.offerDiscountMinor!)}',
              valueColor: Colors.green.shade700,
            ),
          ],
          if (bundle.totalMinor != null) ...[
            SizedBox(height: AppHeight.s4),
            _tinyRow(
              AppTranslation.orderLineTotal,
              formatOrderMoneyMinor(bundle.totalMinor!),
              bold: true,
            ),
          ],
          if (bundle.lines.isNotEmpty) ...[
            SizedBox(height: AppHeight.s10),
            Divider(height: 1, color: ColorManager.textSecondary.withOpacity(0.2)),
            SizedBox(height: AppHeight.s8),
            ...bundle.lines.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: AppPadding.p8),
                child: _LineRow(line: e, compact: true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tinyRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          textStyle: getRegularStyle(
            fontSize: AppFontSize.s11,
            color: ColorManager.textSecondary,
          ),
        ),
        CustomText(
          text: value,
          textStyle: (bold ? getSemiBoldStyle : getRegularStyle)(
            fontSize: AppFontSize.s12,
            color: valueColor ?? ColorManager.titlesColor,
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final OrderLineProductEntity line;
  final bool compact;

  const _LineRow({required this.line, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final disc = line.productDiscountValueMinor;
    final showDisc = disc != null && disc > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: line.productName,
                textStyle: getSemiBoldStyle(
                  fontSize: compact ? AppFontSize.s12 : AppFontSize.s14,
                  color: ColorManager.titlesColor,
                ),
                maxLines: 2,
                textOverflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppHeight.s4),
              Wrap(
                spacing: AppWidth.s8,
                runSpacing: AppHeight.s4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CustomText(
                    text:
                        '${AppTranslation.orderQty} ${line.quantity} · ${AppTranslation.orderUnitPrice} ${formatOrderMoneyMinor(line.unitPriceMinor)}',
                    textStyle: getRegularStyle(
                      fontSize: AppFontSize.s11,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                  if (line.hasUnitDiscount)
                    CustomText(
                      text: formatOrderMoneyMinor(line.originalUnitPriceMinor!),
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s10,
                        color: ColorManager.textSecondary,
                      ).copyWith(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  if (showDisc)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppPadding.p6,
                        vertical: AppPadding.p2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppSize.s8),
                      ),
                      child: CustomText(
                        text:
                            '${AppTranslation.orderDiscount} ${formatOrderMoneyMinor(disc)}',
                        textStyle: getRegularStyle(
                          fontSize: AppFontSize.s10,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: AppWidth.s8),
        CustomText(
          text: formatOrderMoneyMinor(line.lineTotalMinor),
          textStyle: getBoldStyle(
            fontSize: compact ? AppFontSize.s12 : AppFontSize.s14,
            color: ColorManager.primary,
          ),
        ),
      ],
    );
  }
}

class _FallbackProductsList extends StatelessWidget {
  final List<ProductEntity> products;

  const _FallbackProductsList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return CustomText(
        text: AppTranslation.noDataFound,
        textStyle: getRegularStyle(
          fontSize: AppFontSize.s12,
          color: ColorManager.textSecondary,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products
          .map(
            (p) => Padding(
              padding: EdgeInsets.only(bottom: AppPadding.p8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      text: p.name,
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s13,
                        color: ColorManager.titlesColor,
                      ),
                    ),
                  ),
                  CustomText(
                    text: formatOrderMoneyMinor(p.displayPrice),
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s13,
                      color: ColorManager.primary,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

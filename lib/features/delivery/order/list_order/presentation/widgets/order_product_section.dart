import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Product lines for an order row (list tiles + dividers).
class OrderProductSection extends StatelessWidget {
  const OrderProductSection({super.key, required this.order});

  final OrderEntity order;

  static List<String> _productLabels(OrderEntity order) {
    if (order.itemLines.isNotEmpty) {
      return order.itemLines
          .map((l) {
            final n = l.productName.trim();
            if (n.isEmpty) return null;
            return l.quantity > 1 ? '$n × ${l.quantity}' : n;
          })
          .whereType<String>()
          .toList();
    }
    final names = order.products
        .map((p) => p.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isNotEmpty) return names;

    return order.offerBundles
        .expand((b) => b.lines)
        .map((l) {
          final n = l.productName.trim();
          if (n.isEmpty) return null;
          return l.quantity > 1 ? '$n × ${l.quantity}' : n;
        })
        .whereType<String>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final productLabels = _productLabels(order);
    if (productLabels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: AppHeight.s8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: productLabels.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: ColorManager.borderColor.withValues(alpha: 0.35),
          ),
          itemBuilder: (context, index) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              minVerticalPadding: 0,
              horizontalTitleGap: AppWidth.s8,
              leading: Icon(
                Icons.restaurant_menu_outlined,
                size: AppSize.s18,
                color: ColorManager.primary,
              ),
              title: CustomText(
                text: productLabels[index],
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.descriptionColor,
                ),
                maxLines: 2,
                textOverflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
    );
  }
}

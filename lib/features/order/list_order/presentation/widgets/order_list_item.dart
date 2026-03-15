
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart' show AppTranslation;
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';

class OrderListItem extends StatelessWidget {
  final OrderEntity order;

  const OrderListItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppRouter.navigateTo(
          context,
          Routes.orderDetails,
          arguments: {'orderId': order.id},
        );
      },
      child: Card(
        color: ColorManager.defaultWhite,
        margin: EdgeInsets.only(bottom: AppMargin.m16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppPadding.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: AppWidth.s50,
                        height: AppHeight.s50,
                        decoration: BoxDecoration(
                          color: ColorManager.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_cart,
                          color: ColorManager.primary,
                          size: AppSize.s28,
                        ),
                      ),
                      SizedBox(width: AppWidth.s12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: '${AppTranslation.order} #${order.id}',
                            textStyle: getBoldStyle(
                              fontSize: AppFontSize.s18,
                              color: ColorManager.productNameColor,
                            ),
                            maxLines: 2,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppHeight.s4),
                          if (order.status != null) ...[
                            Builder(
                              builder: (context) {
                                final status = OrderStatus.fromString(order.status);
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppPadding.p8,
                                    vertical: AppPadding.p4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: status.color.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.r8),
                                  ),
                                  child: CustomText(
                                    text: status.displayLabel,
                                    textStyle: getSemiBoldStyle(
                                      fontSize: AppFontSize.s10,
                                      color: status.color,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (order.date != null) ...[
                SizedBox(height: AppHeight.s12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: AppSize.s16,
                      color: ColorManager.descriptionColor,
                    ),
                    SizedBox(width: AppWidth.s4),
                    CustomText(
                      text: DateFormat('MMM dd, yyyy - HH:mm')
                          .format(order.date!),
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s12,
                        color: ColorManager.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ],
              if (order.products.isNotEmpty) ...[
                SizedBox(height: AppHeight.s8),
                CustomText(
                  text: '${order.products.length} ${AppTranslation.productsCount}',
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.descriptionColor,
                  ),
                ),
              ],
              if (order.numberOfPeople != null) ...[
                SizedBox(height: AppHeight.s8),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: AppSize.s16,
                      color: ColorManager.descriptionColor,
                    ),
                    SizedBox(width: AppWidth.s4),
                    CustomText(
                      text: '${order.numberOfPeople} ${AppTranslation.people}',
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s12,
                        color: ColorManager.descriptionColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

}


import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:intl/intl.dart';

class OrderDateCard extends StatelessWidget {
  final DateTime date;

  const OrderDateCard({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.defaultWhite,
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: ColorManager.primary,
              size: AppSize.s20,
            ),
            SizedBox(width: AppWidth.s12),
            CustomText(
              text: DateFormat('MMM dd, yyyy - HH:mm').format(date),
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.productNameColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


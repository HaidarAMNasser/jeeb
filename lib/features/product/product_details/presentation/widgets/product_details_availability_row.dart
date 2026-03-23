// import 'package:flutter/material.dart';
// import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
// import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
// import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
// import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
// import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
// import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

// class ProductDetailsAvailabilityRow extends StatelessWidget {
//   final bool? hasStock;
//   final int? stockQuantity;
//   final bool? isAvailable;

//   const ProductDetailsAvailabilityRow({
//     super.key,
//     this.hasStock,
//     this.stockQuantity,
//     this.isAvailable,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CustomText(
//           text: AppTranslation.availability,
//           textStyle: getSemiBoldStyle(
//             fontSize: AppFontSize.s16,
//             color: ColorManager.defaultWhite,
//           ),
//         ),
//         SizedBox(height: AppHeight.s8),
//         Row(
//           children: [
//             Icon(
//               hasStock == true ? Icons.check_circle : Icons.cancel,
//               size: 20,
//               color: hasStock == true
//                   ? Colors.green
//                   : ColorManager.textSecondary,
//             ),
//             SizedBox(width: AppPadding.p8),
//             CustomText(
//               text: hasStock == true
//                   ? AppTranslation.inStockCount(stockQuantity ?? 0)
//                   : AppTranslation.outOfStock,
//               textStyle: getRegularStyle(
//                 fontSize: AppFontSize.s14,
//                 color: ColorManager.textColor,
//               ),
//             ),
//           ],
//         ),
//         if (isAvailable != null)
//           Padding(
//             padding: EdgeInsets.only(top: AppHeight.s4),
//             child: Row(
//               children: [
//                 Icon(
//                   isAvailable!
//                       ? Icons.verified
//                       : Icons.verified_user_outlined,
//                   size: 18,
//                   color: ColorManager.textSecondary,
//                 ),
//                 SizedBox(width: AppPadding.p6),
//                 CustomText(
//                   text: isAvailable!
//                       ? AppTranslation.availableForOrder
//                       : AppTranslation.notAvailable,
//                   textStyle: getRegularStyle(
//                     fontSize: AppFontSize.s13,
//                     color: ColorManager.textSecondary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }
// }

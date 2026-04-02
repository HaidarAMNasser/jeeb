import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_input_dialog.dart';

/// Matches [ConfirmationDialog] / [CustomInputDialog] styling — asks for ETA in minutes before accept-delivery API.
abstract final class AcceptDeliveryEstimatedTimeDialog {
  AcceptDeliveryEstimatedTimeDialog._();

  static const int minMinutes = 5;
  static const int maxMinutes = 240;

  /// Returns minutes if the driver confirms valid input; `null` if cancelled.
  static Future<int?> show(BuildContext context) {
    return CustomInputDialog.show(
      context: context,
      title: AppTranslation.acceptDeliveryEstimatedTimeTitle,
      label: AppTranslation.acceptDeliveryEstimatedTimeLabel,
      hintText: AppTranslation.acceptDeliveryEstimatedTimeHint,
      initialValue: '30',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) {
          return AppTranslation.acceptDeliveryEstimatedTimeEmpty;
        }
        final n = int.tryParse(t);
        if (n == null) {
          return AppTranslation.acceptDeliveryEstimatedTimeInvalid(
            minMinutes,
            maxMinutes,
          );
        }
        if (n < minMinutes || n > maxMinutes) {
          return AppTranslation.acceptDeliveryEstimatedTimeInvalid(
            minMinutes,
            maxMinutes,
          );
        }
        return null;
      },
    ).then((s) => s == null ? null : int.tryParse(s.trim()));
  }
}

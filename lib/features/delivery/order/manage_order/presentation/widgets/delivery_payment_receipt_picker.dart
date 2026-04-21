import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Bottom sheet: pick 1–5 receipt images (JPEG/PNG/WebP) then return local paths.
class DeliveryPaymentReceiptPicker {
  DeliveryPaymentReceiptPicker._();

  static const int maxImages = 5;

  static Future<List<String>?> show(BuildContext context) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ColorManager.primaryDark,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _DeliveryPaymentReceiptPickerBody(),
    );
  }
}

class _DeliveryPaymentReceiptPickerBody extends StatefulWidget {
  const _DeliveryPaymentReceiptPickerBody();

  @override
  State<_DeliveryPaymentReceiptPickerBody> createState() =>
      _DeliveryPaymentReceiptPickerBodyState();
}

class _DeliveryPaymentReceiptPickerBodyState
    extends State<_DeliveryPaymentReceiptPickerBody> {
  final List<String> _paths = [];

  Future<void> _addImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 88);
    if (!mounted || picked.isEmpty) return;

    final remaining = DeliveryPaymentReceiptPicker.maxImages - _paths.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslation.paymentReceiptTooManyImages)),
      );
      return;
    }

    var toAdd = picked.take(remaining).toList();
    if (picked.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslation.paymentReceiptTooManyImages)),
      );
    }

    setState(() {
      for (final x in toAdd) {
        if (!_paths.contains(x.path)) {
          _paths.add(x.path);
        }
      }
    });
  }

  void _removeAt(int i) {
    setState(() => _paths.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppPadding.p16,
        AppPadding.p12,
        AppPadding.p16,
        AppPadding.p16 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorManager.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: AppHeight.s16),
          CustomText(
            text: AppTranslation.uploadPaymentReceipts,
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s18,
              color: ColorManager.defaultWhite,
            ),
          ),
          SizedBox(height: AppHeight.s8),
          CustomText(
            text: AppTranslation.paymentReceiptsSelectHint,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s12,
              color: ColorManager.textSecondary,
            ),
          ),
          SizedBox(height: AppHeight.s16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorManager.primary,
              side: BorderSide(
                color: ColorManager.primary.withValues(alpha: 0.8),
              ),
              backgroundColor: ColorManager.background,
              surfaceTintColor: Colors.transparent,
            ),
            onPressed: _paths.length >= DeliveryPaymentReceiptPicker.maxImages
                ? null
                : _addImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(AppTranslation.paymentReceiptAddImages),
          ),
          if (_paths.isNotEmpty) ...[
            SizedBox(height: AppHeight.s12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _paths.length,
                separatorBuilder: (_, __) => SizedBox(height: AppHeight.s8),
                itemBuilder: (context, i) {
                  final name = _paths[i].replaceAll(r'\', '/').split('/').last;
                  return ListTile(
                    tileColor: ColorManager.background.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.r10),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: CustomText(
                      text: name,
                      textStyle: getMediumStyle(
                        fontSize: AppFontSize.s13,
                        color: ColorManager.primary,
                      ),
                      maxLines: 1,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: ColorManager.textSecondary,
                      ),
                      onPressed: () => _removeAt(i),
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: AppHeight.s20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: ColorManager.background,
              disabledBackgroundColor:
                  ColorManager.primary.withValues(alpha: 0.35),
              disabledForegroundColor:
                  ColorManager.background.withValues(alpha: 0.45),
              surfaceTintColor: Colors.transparent,
            ),
            onPressed: _paths.isEmpty
                ? null
                : () => Navigator.of(context).pop(List<String>.from(_paths)),
            child: Text(AppTranslation.paymentReceiptSubmit),
          ),
        ],
      ),
    );
  }
}

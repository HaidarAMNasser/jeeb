import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/get_settings/data/repositories/get_settings_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryRegisterDialog extends StatefulWidget {
  const DeliveryRegisterDialog({super.key});

  @override
  State<DeliveryRegisterDialog> createState() => _DeliveryRegisterDialogState();
}

class _DeliveryRegisterDialogState extends State<DeliveryRegisterDialog> {
  bool _isLoading = true;
  String? _whatsappNumber;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (kDebugMode) {
      print('DeliveryRegisterDialog: starting fetch of settings');
    }
    final repository = di.sl<GetSettingsRepository>();
    final result = await repository.getSettings();
    result.fold(
      (_) {
        _whatsappNumber = null;
        if (kDebugMode) {
          print('DeliveryRegisterDialog: settings fetch failed or no settings');
        }
      },
      (settings) {
        _whatsappNumber = settings.whatsappNumber;
        if (kDebugMode) {
          print('DeliveryRegisterDialog: fetched whatsappNumber=$_whatsappNumber');
        }
      },
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  String? _normalizeWhatsApp(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  Future<bool> _openWhatsApp() async {
    final normalized = _normalizeWhatsApp(_whatsappNumber);
    if (normalized == null) {
      customToast(msg: AppTranslation.whatsappNotAvailable);
      return false;
    }
    final uri = Uri.parse('https://wa.me/$normalized');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        customToast(msg: AppTranslation.errorOccurred);
      }
      return opened;
    } catch (_) {
      customToast(msg: AppTranslation.errorOccurred);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r20),
      ),
      child: Container(
        padding: EdgeInsets.all(AppPadding.p24),
        decoration: BoxDecoration(
          color: ColorManager.background,
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              text: AppTranslation.deliveryRegisterDialogText,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s16,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            CustomButton(
              text: AppTranslation.contactManagement,
              onPressed: _isLoading
                  ? null
                  : () async {
                      final opened = await _openWhatsApp();
                      if (opened && mounted) {
                        Navigator.of(context).pop('contact');
                      }
                    },
              isLoading: _isLoading,
              color: ColorManager.primary,
            ),
            // Register manually button commented for now
            // SizedBox(height: AppHeight.s12),
            // CustomButton(
            //   text: AppTranslation.registerManually,
            //   onPressed: () => Navigator.of(context).pop('manual'),
            //   isOutlined: true,
            //   color: ColorManager.primary,
            // ),
          ],
        ),
      ),
    );
  }
}

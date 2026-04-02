import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// A reusable input dialog matching the app's language/confirmation dialog UI.
class CustomInputDialog extends StatefulWidget {
  final String title;
  final String? label;
  final String? hintText;
  final String? initialValue;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const CustomInputDialog({
    super.key,
    required this.title,
    this.label,
    this.hintText,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
  });

  /// Shows the dialog and returns the entered text if confirmed, otherwise null.
  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? label,
    String? hintText,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => CustomInputDialog(
        title: title,
        label: label,
        hintText: hintText,
        initialValue: initialValue,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
      ),
    );
  }

  @override
  State<CustomInputDialog> createState() => _CustomInputDialogState();
}

class _CustomInputDialogState extends State<CustomInputDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
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
              text: widget.title,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.titlesColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppHeight.s24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                style: getRegularStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.titlesColor,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hintText,
                  labelStyle: getRegularStyle(
                    color: ColorManager.textColor,
                    fontSize: AppFontSize.s14,
                  ),
                  hintStyle: getRegularStyle(
                    color: ColorManager.descriptionColor,
                    fontSize: AppFontSize.s13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    borderSide: BorderSide(color: ColorManager.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    borderSide: BorderSide(color: ColorManager.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    borderSide: BorderSide(color: ColorManager.error),
                  ),
                  filled: true,
                  fillColor: ColorManager.background,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p16,
                    vertical: AppHeight.s16,
                  ),
                ),
                validator: widget.validator,
              ),
            ),
            SizedBox(height: AppHeight.s24),
            CustomButton(
              text: AppTranslation.cancel,
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
              color: ColorManager.primary,
            ),
            SizedBox(height: AppHeight.s16),
            CustomButton(
              text: AppTranslation.confirm,
              onPressed: _onConfirm,
              color: ColorManager.primary,
            ),
          ],
        ),
      ),
    );
  }
}

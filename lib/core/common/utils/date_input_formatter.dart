import 'package:flutter/services.dart';

/// Formats input as DD/MM/YYYY by inserting "/" automatically.
/// User types digits only; slashes are added after day and month.
class DateSlashInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 8) {
      // Limit to DDMMYYYY
      final truncated = text.substring(0, 8);
      return _format(truncated, newValue.selection, newValue.composing);
    }
    return _format(text, newValue.selection, newValue.composing);
  }

  TextEditingValue _format(
    String digits,
    TextSelection selection,
    TextRange composing,
  ) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    final offset = formatted.length.clamp(0, formatted.length);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
      composing: composing,
    );
  }
}

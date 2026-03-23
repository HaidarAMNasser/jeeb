import 'package:flutter/material.dart';

/// Application Color Constants
class ColorManager {
  ColorManager._();

  // Primary Colors
  static const Color primary = Color.fromARGB(255, 226, 87, 6);

  static const Color primaryDark = Color.fromARGB(255, 39, 37, 37);
  static const Color primaryLight = Color(0xFF7C8FFF);
  static const Color defaultYellow = Color(0xFFF59E0B);
  static const Color defaultWhite = Color.fromARGB(255, 255, 234, 222);
  static const Color transparent = Colors.transparent;

  // Secondary Colors
  static const Color secondary = Color(0xFF764BA2);
  static const Color secondaryDark = Color(0xFF6B4190);
  static const Color secondaryLight = Color(0xFF8B5BB5);

  // Accent Colors
  static const Color accent = Color(0xFFF093FB);
  static const Color accentDark = Color(0xFFE080E8);
  static const Color accentLight = Color(0xFFFFB3FF);

  // Background Colors
  static const Color background = Color.fromARGB(255, 39, 37, 37);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF16213E);

  // Text Colors
  static const Color textPrimary = Color(0xFFB2BEC3);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textColor = Color(0xFF6B7280);
  static const Color textDarkColor = Color.fromARGB(255, 64, 68, 70);
  static const Color titlesColor = Color(0xFFFFFFFF);
  static const Color productNameColor = Color(0xFF1A1A1A);
  static const Color descriptionColor = Color(0xFF6B7280);

  // Product List Item Colors
  static const Color lightPrimary = Color(0xFFFFE5D4);
  static const Color categoryTextColor = Color(0xFFE25727);
  static const Color priceColor = Color(0xFFE25727);
  static const Color ratingBackgroundColor = Color(0xFFFFF4E0);

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDAA5D);
  static const Color error = Color.fromARGB(255, 112, 7, 7);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color info = Color(0xFF74B9FF);

  // Button States
  static const Color closeDialogColor = Color(
    0xFF9E9E9E,
  ); // Disabled/Grey button color

  // Border & Divider Colors
  static const Color borderColor = Color(0xffEAECED);
  static const Color divider = Color(0xFFECF0F1);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFFF5576C)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundDark, surfaceDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  );
}

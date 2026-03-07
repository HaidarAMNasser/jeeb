// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'colors.dart';
// import 'font_manager.dart';

// /// Application Theme Configuration
// /// Provides Light and Dark theme configurations
// class AppTheme {
//   // Private constructor to prevent instantiation
//   AppTheme._();

//   /// Light Theme Configuration
//   static ThemeData get lightTheme {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       primaryColor: ColorManager.primary,
//       scaffoldBackgroundColor: ColorManager.background,
//       colorScheme: ColorScheme.light(
//         primary: ColorManager.primary,
//         secondary: ColorManager.secondary,
//         error: ColorManager.error,
//         surface: ColorManager.surface,
//         background: ColorManager.background,
//         onPrimary: ColorManager.textOnPrimary,
//         onSecondary: ColorManager.textOnPrimary,
//         onError: ColorManager.textOnPrimary,
//         onSurface: ColorManager.textPrimary,
//         onBackground: ColorManager.textPrimary,
//       ),

//       // AppBar Theme
//       appBarTheme: AppBarTheme(
//         elevation: 0,
//         centerTitle: true,
//         backgroundColor: ColorManager.background,
//         foregroundColor: ColorManager.textPrimary,
//         systemOverlayStyle: SystemUiOverlayStyle.dark,
//         titleTextStyle: FontManager.h2.copyWith(
//           color: ColorManager.textPrimary,
//         ),
//       ),

//       // Text Theme
//       textTheme: TextTheme(
//         displayLarge: FontManager.h1.copyWith(color: ColorManager.textPrimary),
//         displayMedium: FontManager.h2.copyWith(color: ColorManager.textPrimary),
//         displaySmall: FontManager.h3.copyWith(color: ColorManager.textPrimary),
//         headlineMedium: FontManager.h4.copyWith(
//           color: ColorManager.textPrimary,
//         ),
//         bodyLarge: FontManager.bodyLarge.copyWith(
//           color: ColorManager.textPrimary,
//         ),
//         bodyMedium: FontManager.bodyMedium.copyWith(
//           color: ColorManager.textSecondary,
//         ),
//         bodySmall: FontManager.bodySmall.copyWith(
//           color: ColorManager.textSecondary,
//         ),
//       ),

//       // Card Theme
//       // cardTheme: CardTheme(
//       //   elevation: 2,
//       //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       //   color: AppColors.surface,
//       // ),

//       // Input Decoration Theme
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: ColorManager.surface,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.border),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.primary, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.error),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//       ),

//       // Elevated Button Theme
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: ColorManager.primary,
//           foregroundColor: ColorManager.textOnPrimary,
//           elevation: 2,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           textStyle: FontManager.button,
//         ),
//       ),

//       // Text Button Theme
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: ColorManager.primary,
//           textStyle: FontManager.button,
//         ),
//       ),

//       // Icon Theme
//       iconTheme: IconThemeData(color: ColorManager.textPrimary, size: 24),

//       // Divider Theme
//       dividerTheme: DividerThemeData(
//         color: ColorManager.divider,
//         thickness: 1,
//         space: 1,
//       ),
//     );
//   }

//   /// Dark Theme Configuration
//   static ThemeData get darkTheme {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       primaryColor: ColorManager.primary,
//       scaffoldBackgroundColor: ColorManager.backgroundDark,
//       colorScheme: ColorScheme.dark(
//         primary: ColorManager.primary,
//         secondary: ColorManager.secondary,
//         error: ColorManager.error,
//         surface: ColorManager.surfaceDark,
//         background: ColorManager.backgroundDark,
//         onPrimary: ColorManager.textOnPrimary,
//         onSecondary: ColorManager.textOnPrimary,
//         onError: ColorManager.textOnPrimary,
//         onSurface: ColorManager.textLight,
//         onBackground: ColorManager.textLight,
//       ),

//       // AppBar Theme
//       appBarTheme: AppBarTheme(
//         elevation: 0,
//         centerTitle: true,
//         backgroundColor: ColorManager.backgroundDark,
//         foregroundColor: ColorManager.textLight,
//         systemOverlayStyle: SystemUiOverlayStyle.light,
//         titleTextStyle: FontManager.h2.copyWith(color: ColorManager.textLight),
//       ),

//       // Text Theme
//       textTheme: TextTheme(
//         displayLarge: FontManager.h1.copyWith(color: ColorManager.textLight),
//         displayMedium: FontManager.h2.copyWith(color: ColorManager.textLight),
//         displaySmall: FontManager.h3.copyWith(color: ColorManager.textLight),
//         headlineMedium: FontManager.h4.copyWith(color: ColorManager.textLight),
//         bodyLarge: FontManager.bodyLarge.copyWith(
//           color: ColorManager.textLight,
//         ),
//         bodyMedium: FontManager.bodyMedium.copyWith(
//           color: ColorManager.textSecondary,
//         ),
//         bodySmall: FontManager.bodySmall.copyWith(
//           color: ColorManager.textSecondary,
//         ),
//       ),

//       // Card Theme
//       // cardTheme: CardTheme(
//       //   elevation: 2,
//       //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       //   color: AppColors.surfaceDark,
//       // ),

//       // Input Decoration Theme
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: ColorManager.surfaceDark,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.border),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.primary, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: ColorManager.error),
//         ),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 16,
//         ),
//       ),

//       // Elevated Button Theme
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: ColorManager.primary,
//           foregroundColor: ColorManager.textOnPrimary,
//           elevation: 2,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           textStyle: FontManager.button,
//         ),
//       ),

//       // Text Button Theme
//       textButtonTheme: TextButtonThemeData(
//         style: TextButton.styleFrom(
//           foregroundColor: ColorManager.primary,
//           textStyle: FontManager.button,
//         ),
//       ),

//       // Icon Theme
//       iconTheme: IconThemeData(color: ColorManager.textLight, size: 24),

//       // Divider Theme
//       dividerTheme: DividerThemeData(
//         color: ColorManager.border,
//         thickness: 1,
//         space: 1,
//       ),
//     );
//   }
// }

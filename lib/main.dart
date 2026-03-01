import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/presentation/routes/route_manager.dart';
import 'core/presentation/routes/routes.dart';
import 'core/presentation/routes/navigation_service.dart';
import 'core/infrastructure/di/dependency_injection.dart' as di;
import 'core/presentation/localization/localization_manager.dart';
import 'core/infrastructure/services/storage_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize dependency injection
  await di.init();

  // Get stored language from SharedPreferences
  final storageService = di.sl<StorageService>();
  final storedLanguage = storageService.getAppLanguage();
  final startLocale = storedLanguage.isEmpty
      ? LocalizationManager.fallbackLocale
      : (storedLanguage == 'ar' ? const Locale('ar') : LocalizationManager.fallbackLocale);

  runApp(
    EasyLocalization(
      supportedLocales: LocalizationManager.supportedLocales,
      path: LocalizationManager.translationsPath,
      fallbackLocale: LocalizationManager.fallbackLocale,
      startLocale: startLocale,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Jeeb App',
          debugShowCheckedModeBanner: false,
          // theme: AppTheme.lightTheme,
          // darkTheme:  AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          navigatorKey: di.sl<NavigationService>().navigationKey,
          initialRoute: Routes.splash,
          onGenerateRoute: AppRouter.generateRoute,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}

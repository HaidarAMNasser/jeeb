import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/presentation/routes/route_manager.dart';
import 'core/presentation/routes/routes.dart';
import 'core/presentation/routes/navigation_service.dart';
import 'core/infrastructure/di/dependency_injection.dart' as di;
import 'core/presentation/localization/localization_manager.dart';
import 'core/infrastructure/services/notification_service.dart';
import 'core/infrastructure/services/storage_service.dart';
import 'features/notification/update_token/presentation/bloc/update_token_bloc.dart';
import 'features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await di.init();
  await Firebase.initializeApp();

  // Chucker
  // ChuckerFlutter.showOnRelease = !AppConfig.isProduction;
  // ChuckerFlutter.showNotification = false;

  // Get stored language from SharedPreferences
  final storageService = di.sl<StorageService>();
  final storedLanguage = storageService.getAppLanguage();
  final startLocale = storedLanguage.isEmpty
      ? LocalizationManager.fallbackLocale
      : (storedLanguage == 'ar'
            ? const Locale('ar')
            : LocalizationManager.fallbackLocale);

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final UpdateTokenBloc _updateTokenBloc;
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _updateTokenBloc = di.sl<UpdateTokenBloc>();
    _updateTokenBloc.add(const UpdateTokenInitializeRequested());
    _profileBloc = di.sl<ProfileBloc>()..add(const GetProfile());
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final notificationService = di.sl<NotificationService>();
    await notificationService.initialize(
      onToken: (token) => _updateTokenBloc.add(UpdateTokenReceived(token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _updateTokenBloc),
        BlocProvider.value(value: _profileBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Zawada',
            debugShowCheckedModeBanner: false,
            // navigatorObservers: [
            //   ChuckerFlutter.navigatorObserver,
            // ],
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
      ),
    );
  }
}

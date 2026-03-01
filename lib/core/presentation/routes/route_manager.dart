import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes.dart';
import 'navigation_service.dart';
import '../../infrastructure/di/dependency_injection.dart' as di;
import '../../../features/splash/presentation/pages/splash_page.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../features/auth/login/presentation/pages/login_page.dart';
import '../../../features/auth/login/presentation/bloc/login_bloc.dart';
import '../../../features/auth/register/presentation/pages/register_page.dart';
import '../../../features/auth/register/presentation/bloc/register_bloc.dart';
import '../../../features/auth/forgot_password/presentation/pages/forgot_password_page.dart';
import '../../../features/auth/forgot_password/presentation/bloc/forgot_password_bloc.dart';
import '../../../features/auth/reset_password/presentation/pages/reset_password_page.dart';
import '../../../features/auth/reset_password/presentation/bloc/reset_password_bloc.dart';
import '../../../features/auth/verify/presentation/pages/verify_page.dart';
import '../../../features/auth/verify/presentation/bloc/verify_bloc.dart';
import '../../../features/auth/profile/presentation/pages/profile_page.dart';
import '../../../features/auth/profile/presentation/bloc/profile_bloc.dart';
import '../../../features/country/presentation/bloc/country_bloc.dart';
import '../../../features/city/presentation/bloc/city_bloc.dart';

/// Application Router
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case Routes.splash:
        return _buildRoute(const SplashPage(), settings);

      case Routes.onboarding:
        return _buildRouteWithBloc<OnboardingBloc>(
          const OnboardingPage(),
          settings,
          bloc: () => di.sl<OnboardingBloc>(),
        );

      case Routes.login:
        return _buildRouteWithBloc<LoginBloc>(
          const LoginPage(),
          settings,
          bloc: () => di.sl<LoginBloc>(),
        );

      case Routes.register:
        return _buildRouteWithAuthCountryCityBlocs<RegisterBloc>(
          const RegisterPage(),
          settings,
          authBloc: () => di.sl<RegisterBloc>(),
        );

      case Routes.forgotPassword:
        return _buildRouteWithBloc<ForgotPasswordBloc>(
          const ForgotPasswordPage(),
          settings,
          bloc: () => di.sl<ForgotPasswordBloc>(),
        );

      case Routes.resetPassword:
        return _buildRouteWithBloc<ResetPasswordBloc>(
          const ResetPasswordPage(),
          settings,
          bloc: () => di.sl<ResetPasswordBloc>(),
        );

      case Routes.verify:
        return _buildRouteWithBloc<VerifyBloc>(
          const VerifyPage(),
          settings,
          bloc: () => di.sl<VerifyBloc>(),
        );

      case Routes.profile:
        return _buildRouteWithAuthCountryCityBlocs<ProfileBloc>(
          const ProfilePage(),
          settings,
          authBloc: () => di.sl<ProfileBloc>(),
        );

      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Build route with auth screen that needs Country + City blocs (e.g. register, profile)
  static PageRouteBuilder _buildRouteWithAuthCountryCityBlocs<T extends StateStreamableSource<Object?>>(
    Widget page,
    RouteSettings settings, {
    required T Function() authBloc,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) =>
          MultiBlocProvider(
        providers: [
          BlocProvider<T>(create: (_) => authBloc()),
          BlocProvider<CountryBloc>(create: (_) => di.sl<CountryBloc>()),
          BlocProvider<CityBloc>(create: (_) => di.sl<CityBloc>()),
        ],
        child: page,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Build route with a single BLoC provider
  /// Usage: _buildRouteWithBloc(MyScreen(), settings, bloc: () => di.sl<MyBloc>())
  static PageRouteBuilder _buildRouteWithBloc<
    T extends StateStreamableSource<Object?>
  >(Widget page, RouteSettings settings, {required T Function() bloc}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) =>
          BlocProvider<T>(create: (_) => bloc(), child: page),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Build route with an existing BLoC value (passed from previous screen)
  /// Usage: _buildRouteWithBlocValue(MyScreen(), settings, bloc: existingBloc)
  // ignore: unused_element
  static PageRouteBuilder _buildRouteWithBlocValue<
    T extends StateStreamableSource<Object?>
  >(Widget page, RouteSettings settings, {required T bloc}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) =>
          BlocProvider<T>.value(value: bloc, child: page),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Build route with auto-injected BLoCs from dependency injection
  /// Just pass the BLoC factory functions and it will automatically wrap with BlocProvider
  /// Parameters are passed via RouteSettings.arguments as Map<String, dynamic>
  ///
  /// Usage with parameters:
  /// ```dart
  /// final args = settings.arguments as Map<String, dynamic>?;
  /// return _buildRouteWithBlocs(
  ///   MyScreen(
  ///     id: args?['id'] as String?,
  ///     name: args?['name'] as String?,
  ///   ),
  ///   settings,
  ///   blocs: [() => di.sl<MyBloc>()],
  /// );
  /// ```
  // ignore: unused_element
  static PageRouteBuilder _buildRouteWithBlocs(
    Widget page,
    RouteSettings settings, {
    required List<dynamic Function()> blocs,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        // If single BLoC, use BlocProvider directly
        if (blocs.length == 1) {
          final bloc = blocs.first()();
          return BlocProvider.value(value: bloc, child: page);
        }

        // If multiple BLoCs, create providers and use MultiBlocProvider
        final providers = blocs.map((blocFactory) {
          final bloc = blocFactory();
          return BlocProvider.value(value: bloc);
        }).toList();

        return MultiBlocProvider(providers: providers, child: page);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Navigation methods using NavigationService
  static void navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    NavigationService().pushNamed(routeName, arguments: arguments);
  }

  static void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    NavigationService().pushReplacementNamed(routeName, arguments: arguments);
  }

  static void navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    NavigationService().pushNamedAndRemoveUntil(
      routeName,
      arguments: arguments,
    );
  }

  static void goBack(BuildContext context) {
    NavigationService().back();
  }
}

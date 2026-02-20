import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes.dart';
import 'navigation_service.dart';
// import '../dependency_injection/dependency_injection.dart' as di;
import '../../../features/splash/splash_screen.dart';
import '../../../features/onboarding/onboarding_screen.dart';

/// Application Router
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case Routes.splash:
        return _buildRoute(const SplashScreen(), settings);

      case Routes.onboarding:
        // Example: Auto-inject BLoCs - just pass the bloc factory functions!
        // return _buildRouteWithBlocs(
        //   const OnboardingScreen(),
        //   settings,
        //   blocs: [() => di.sl<OnboardingBloc>()],
        // );
        return _buildRoute(const OnboardingScreen(), settings);

      case Routes.login:
        // Example: Auto-inject single BLoC with parameters (same as old project)
        // return _buildRouteWithBlocs(
        //   LoginScreen(
        //     userId: args?['userId'] as String?,
        //     email: args?['email'] as String?,
        //   ),
        //   settings,
        //   blocs: [() => di.sl<LoginBloc>()],
        // );
        return _buildRoute(
          Scaffold(body: Center(child: Text('Login Screen'))),
          settings,
        );

      // Example: Route with parameters and multiple BLoCs (same as old project)
      // case Routes.profile:
      //   return _buildRouteWithBlocs(
      //     ProfileScreen(
      //       userId: args?['userId'] as String,
      //       userName: args?['userName'] as String?,
      //       canEdit: args?['canEdit'] as bool? ?? false,
      //     ),
      //     settings,
      //     blocs: [
      //       () => di.sl<ProfileBloc>(),
      //       () => di.sl<SettingsBloc>(),
      //     ],
      //   );

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

  /// Build route with a single BLoC provider
  /// Usage: _buildRouteWithBloc(MyScreen(), settings, bloc: () => di.sl<MyBloc>())
  // ignore: unused_element
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

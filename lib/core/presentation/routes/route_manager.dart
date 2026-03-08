import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/auth/profile/presentation/pages/profile_page.dart';
import 'routes.dart';
import 'navigation_service.dart';
// import '../dependency_injection/dependency_injection.dart' as di;
import '../../../features/splash/presentation/pages/splash_page.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../../features/onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../../features/product/list_product/presentation/pages/list_product_page.dart';
import '../../../features/product/list_product/presentation/bloc/list_product_bloc.dart';
import '../../../features/product/list_product/data/repositories/list_product_repository.dart';
import '../../../features/product/product_details/presentation/pages/product_details_page.dart';
import '../../../features/product/product_details/presentation/bloc/product_details_bloc.dart';
import '../../../features/product/product_details/data/repositories/product_details_repository.dart';
import '../../../features/auth/login/presentation/pages/login_page.dart';
import '../../../features/auth/login/presentation/bloc/login_bloc.dart';
import '../../../features/auth/register/presentation/pages/register_page.dart';
import '../../../features/auth/register/presentation/bloc/register_bloc.dart';
import '../../../features/auth/verify/presentation/pages/verify_page.dart';
import '../../../features/auth/verify/presentation/bloc/verify_bloc.dart';
import '../../../features/auth/forgot_password/presentation/pages/forgot_password_page.dart';
import '../../../features/auth/forgot_password/presentation/bloc/forgot_password_bloc.dart';
import '../../../features/auth/reset_password/presentation/pages/reset_password_page.dart';
import '../../../features/auth/reset_password/presentation/bloc/reset_password_bloc.dart';
import '../../../features/auth/logout/presentation/bloc/logout_bloc.dart';
import '../../../features/country/presentation/bloc/country_bloc.dart';
import '../../../features/city/presentation/bloc/city_bloc.dart';
import '../../../features/order/list_order/presentation/pages/list_order_page.dart';
import '../../../features/order/list_order/presentation/bloc/list_order_bloc.dart';
import '../../../features/order/order_details/presentation/pages/order_details_page.dart';
import '../../../features/order/order_details/presentation/bloc/order_details_bloc.dart';
import '../../../features/main_navigation/presentation/pages/main_navigation_page.dart';
import '../../../features/merchant/list_merchant/presentation/pages/list_merchant_page.dart';
import '../../../features/merchant/list_merchant/presentation/bloc/list_merchant_bloc.dart';
import '../../../features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import '../../../features/offers/presentation/pages/offers_page.dart';
import '../../../features/offers/presentation/bloc/offers_bloc.dart';

import '../../infrastructure/di/dependency_injection.dart' as di;

/// Application Router
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case Routes.splash:
        return _buildRoute(const SplashPage(), settings);

      case Routes.onboarding:
        return _buildRouteWithBloc(
          const OnboardingPage(),
          settings,
          bloc: () => OnboardingBloc(),
        );

      case Routes.login:
        return _buildRouteWithBloc(
          const LoginPage(),
          settings,
          bloc: () => di.sl<LoginBloc>(),
        );

      case Routes.register:
        return _buildRouteWithBlocs(
          const RegisterPage(),
          settings,
          providers: [
            BlocProvider<RegisterBloc>(create: (_) => di.sl<RegisterBloc>()),
            BlocProvider<CountryBloc>(create: (_) => di.sl<CountryBloc>()),
            BlocProvider<CityBloc>(create: (_) => di.sl<CityBloc>()),
          ],
        );

      case Routes.verify:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';
        return _buildRouteWithBloc(
          VerifyPage(email: email),
          settings,
          bloc: () => di.sl<VerifyBloc>(),
        );

      case Routes.forgotPassword:
        return _buildRouteWithBloc(
          const ForgotPasswordPage(),
          settings,
          bloc: () => di.sl<ForgotPasswordBloc>(),
        );

      case Routes.resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        final email = args?['email'] as String? ?? '';
        return _buildRouteWithBloc(
          ResetPasswordPage(email: email),
          settings,
          bloc: () => di.sl<ResetPasswordBloc>(),
        );

      case Routes.profile:
        return _buildRouteWithBlocs(
          const ProfilePage(),
          settings,
          providers: [
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()..add(const GetProfile()),
            ),
            BlocProvider<LogoutBloc>(create: (_) => di.sl<LogoutBloc>()),
          ],
        );

      case Routes.products:
        return _buildRouteWithBloc(
          const ListProductPage(),
          settings,
          bloc: () =>
              ListProductBloc(di.sl<ListProductRepository>())
                ..add(const GetProductsEvent()),
        );

      case Routes.productDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final productId = args?['productId'] as String? ?? '';
        return _buildRouteWithBlocs(
          ProductDetailsPage(productId: productId),
          settings,
          providers: [
            BlocProvider<ProductDetailsBloc>(
              create: (_) =>
                  ProductDetailsBloc(di.sl<ProductDetailsRepository>()),
            ),
          ],
        );

      case Routes.mainNavigation:
        return _buildRoute(const MainNavigationPage(), settings);

      case Routes.merchants:
        return _buildRouteWithBloc(
          const ListMerchantPage(),
          settings,
          bloc: () =>
              ListMerchantBloc(di.sl<ListMerchantRepository>())
                ..add(const GetMerchantsEvent()),
        );

      case Routes.orders:
        return _buildRouteWithBlocs(
          const ListOrderPage(),
          settings,
          providers: [
            BlocProvider<ListOrderBloc>(create: (_) => di.sl<ListOrderBloc>()),
          ],
        );

      case Routes.orderDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final orderId = args?['orderId'] as String? ?? '';
        if (orderId.isEmpty) {
          return _buildRoute(
            Scaffold(body: Center(child: Text('Order ID not provided'))),
            settings,
          );
        }
        return _buildRouteWithBlocs(
          OrderDetailsPage(orderId: orderId),
          settings,
          providers: [
            BlocProvider<OrderDetailsBloc>(
              create: (_) =>
                  di.sl<OrderDetailsBloc>()..add(GetOrderDetailsEvent(orderId)),
            ),
          ],
        );

      case Routes.offers:
        return _buildRouteWithBloc(
          const OffersPage(),
          settings,
          bloc: () => di.sl<OffersBloc>(),
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

  /// Build route with multiple BLoC providers
  /// Usage:
  /// ```dart
  /// final args = settings.arguments as Map<String, dynamic>?;
  /// return _buildRouteWithBlocs(
  ///   MyScreen(id: args?['id']),
  ///   settings,
  ///   providers: [
  ///     BlocProvider(create: (_) => di.sl<MyBloc>()),
  ///     BlocProvider(create: (_) => di.sl<AnotherBloc>()),
  ///   ],
  /// );
  /// ```
  static PageRouteBuilder _buildRouteWithBlocs(
    Widget page,
    RouteSettings settings, {
    required List<BlocProvider> providers,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
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

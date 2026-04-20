import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'routes.dart';
import 'navigation_service.dart';
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
import '../../../features/auth/register/presentation/pages/delivery_waiting_page.dart';
import '../../../features/auth/register/presentation/bloc/register_bloc.dart';
import '../../../features/auth/verify/presentation/pages/verify_page.dart';
import '../../../features/auth/verify/presentation/bloc/verify_bloc.dart';
import '../../../features/auth/forgot_password/presentation/pages/forgot_password_page.dart';
import '../../../features/auth/forgot_password/presentation/bloc/forgot_password_bloc.dart';
import '../../../features/auth/reset_password/presentation/pages/reset_password_page.dart';
import '../../../features/auth/reset_password/presentation/bloc/reset_password_bloc.dart';
import '../../../features/auth/profile/presentation/pages/profile_page.dart';
import '../../../features/auth/profile/presentation/pages/change_password_page.dart';
import '../../../features/auth/profile/presentation/bloc/profile_bloc.dart';
import '../../../features/auth/logout/presentation/bloc/logout_bloc.dart';
import '../../../features/country/presentation/bloc/country_bloc.dart';
import '../../../features/city/presentation/bloc/city_bloc.dart';
import '../../../features/delivery/order/list_order/presentation/pages/list_order_page.dart';
import '../../../features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import '../../../features/basket/order_status_section/presentation/bloc/order_status_bloc.dart';
import '../../../features/basket/order_status_section/presentation/pages/order_status_page.dart';
import '../../../features/delivery/order/order_details/domain/entities/order_status.dart';
import '../../../features/delivery/order/order_details/presentation/pages/order_details_page.dart';
import '../../../features/delivery/order/order_details/presentation/bloc/order_details_bloc.dart';
import '../../../features/delivery/delivery_section/delivery_order_details/screens/delivery_order_details_page.dart';
import '../../../features/delivery/pay_admin/presentation/bloc/pay_admin_bloc.dart';
import '../../../features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import '../../../features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import '../../../features/main_navigation/presentation/pages/main_navigation_page.dart';
import '../../../features/client_home/presentation/pages/client_home_page.dart';
import '../../../features/merchant/list_merchant/presentation/pages/list_merchant_page.dart';
import '../../../features/merchant/list_merchant/presentation/bloc/list_merchant_bloc.dart';
import '../../../features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import '../../../features/merchant/merchant_details/presentation/pages/merchant_details_page.dart';
import '../../../features/merchant/merchant_details/presentation/bloc/merchant_details_bloc.dart';
import '../../../features/merchant/merchant_details/data/repositories/merchant_details_repository.dart';

import '../../../features/offer/list_offer/presentation/pages/list_offer_page.dart';
import '../../../features/offer/list_offer/presentation/bloc/list_offer_bloc.dart';
import '../../../features/offer/list_offer/data/repositories/list_offer_repository.dart';
import '../../../features/offer/offer_details/presentation/pages/offer_details_page.dart';
import '../../../features/offer/offer_details/presentation/bloc/offer_details_bloc.dart';
import '../../../features/offer/offer_details/data/repositories/offer_details_repository.dart';
import '../../../features/favorites/presentation/pages/favorites_page.dart';
import '../../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../../features/basket/manage_cart/presentation/bloc/manage_cart_bloc.dart';

import '../../infrastructure/di/dependency_injection.dart' as di;

double? _routeArgAsDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _routeArgString(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  return value.toString().trim().isEmpty ? null : value.toString().trim();
}

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
        final registerBloc = args?['registerBloc'] as RegisterBloc?;
        final expectDeliveryWaiting = args?['expectDeliveryWaiting'] == true;
        return _buildRouteWithBlocs(
          VerifyPage(
            email: email,
            expectDeliveryWaiting: expectDeliveryWaiting,
          ),
          settings,
          providers: [
            BlocProvider<VerifyBloc>(create: (_) => di.sl<VerifyBloc>()),
            if (registerBloc != null)
              BlocProvider<RegisterBloc>.value(value: registerBloc),
          ],
        );

      case Routes.deliveryWaiting:
        return _buildRoute(const DeliveryWaitingPage(), settings);

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

      case Routes.changePassword:
        return _buildRouteWithBlocs(
          const ChangePasswordPage(),
          settings,
          providers: [
            BlocProvider.value(value: di.sl<ProfileBloc>()),
          ],
        );

      case Routes.profile:
        return _buildRouteWithBlocs(
          const ProfilePage(),
          settings,
          providers: [
            BlocProvider<LogoutBloc>(create: (_) => di.sl<LogoutBloc>()),
          ],
        );

      case Routes.products:
        final productArgs = settings.arguments as Map<String, dynamic>?;
        final productMerchantId = productArgs?['merchantId'] as String?;
        return _buildRouteWithBlocs(
          ListProductPage(merchantId: productMerchantId),
          settings,
          providers: [
            BlocProvider<ListProductBloc>(
              create: (_) =>
                  ListProductBloc(di.sl<ListProductRepository>())
                    ..add(GetProductsEvent(merchantId: productMerchantId)),
            ),
            BlocProvider<ManageCartBloc>.value(value: di.sl<ManageCartBloc>()),
          ],
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
            BlocProvider<ManageCartBloc>.value(value: di.sl<ManageCartBloc>()),
          ],
        );

      case Routes.mainNavigation:
        return _buildRoute(const MainNavigationPage(), settings);

      case Routes.clientHome:
        return _buildRoute(
          MultiBlocProvider(
            providers: [
              BlocProvider<FavoritesBloc>.value(value: di.sl<FavoritesBloc>()),
              BlocProvider<ClientHomeBloc>(
                create: (_) => di.sl<ClientHomeBloc>(),
              ),
            ],
            child: const ClientHomePage(),
          ),
          settings,
        );

      case Routes.merchants:
        return _buildRouteWithBloc(
          const ListMerchantPage(),
          settings,
          bloc: () =>
              ListMerchantBloc(di.sl<ListMerchantRepository>())
                ..add(const GetMerchantsEvent()),
        );

      case Routes.merchantDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final merchantId = args?['merchantId'] as String? ?? '';
        if (merchantId.isEmpty) {
          return _buildRoute(
            Scaffold(body: Center(child: Text('Merchant ID not provided'))),
            settings,
          );
        }
        return _buildRouteWithBlocs(
          MerchantDetailsPage(merchantId: merchantId),
          settings,
          providers: [
            BlocProvider<MerchantDetailsBloc>(
              create: (_) =>
                  MerchantDetailsBloc(di.sl<MerchantDetailsRepository>()),
            ),
            BlocProvider<ListProductBloc>(
              create: (_) => ListProductBloc(di.sl<ListProductRepository>()),
            ),
            BlocProvider<ListOfferBloc>(
              create: (_) => ListOfferBloc(di.sl<ListOfferRepository>()),
            ),
          ],
        );

      case Routes.orders:
        return _buildRouteWithBlocs(
          const ListOrderPage(),
          settings,
          providers: [
            BlocProvider<ListOrderBloc>(
              create: (_) =>
                  di.sl<ListOrderBloc>()..add(const GetOrdersEvent()),
            ),
          ],
        );

      case Routes.orderStatus:
        final osArgs = settings.arguments as Map<String, dynamic>?;
        final orderStatusId = osArgs?['orderId'] as String? ?? '';
        final initialStatus = OrderStatus.fromString(
          osArgs?['initialStatus'] as String?,
        );
        final deliveryLat = _routeArgAsDouble(osArgs?['deliveryLatitude']);
        final deliveryLng = _routeArgAsDouble(osArgs?['deliveryLongitude']);
        final deliveryManName = _routeArgString(osArgs?['deliveryManName']);
        final deliveryManPhone = _routeArgString(osArgs?['deliveryManPhone']);
        if (orderStatusId.isEmpty) {
          return _buildRoute(
            Scaffold(body: Center(child: Text('Order ID not provided'))),
            settings,
          );
        }
        return _buildRouteWithBlocs(
          const OrderStatusPage(),
          settings,
          providers: [
            BlocProvider<OrderStatusBloc>(
              create: (_) => OrderStatusBloc(
                orderId: orderStatusId,
                initialStatus: initialStatus,
                deliveryLatitude: deliveryLat,
                deliveryLongitude: deliveryLng,
                deliveryManName: deliveryManName,
                deliveryManPhone: deliveryManPhone,
                orderStatusRtdb: di.sl<OrderStatusRtdbService>(),
              ),
            ),
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

      case Routes.deliveryOrderDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final orderId = args?['orderId'] as String? ?? '';
        if (orderId.isEmpty) {
          return _buildRoute(
            Scaffold(body: Center(child: Text('Order ID not provided'))),
            settings,
          );
        }
        return _buildRouteWithBlocs(
          DeliveryOrderDetailsPage(orderId: orderId),
          settings,
          providers: [
            BlocProvider<ManageOrderBloc>.value(
              value: di.sl<ManageOrderBloc>(),
            ),
            BlocProvider<DeliveryHomeBloc>.value(
              value: di.sl<DeliveryHomeBloc>(),
            ),
            BlocProvider<PayAdminBloc>(
              create: (_) => di.sl<PayAdminBloc>(),
            ),
          ],
        );

      case Routes.offers:
        final offerArgs = settings.arguments as Map<String, dynamic>?;
        final offerMerchantId = offerArgs?['merchantId'] as String?;
        return _buildRouteWithBloc(
          const ListOfferPage(),
          settings,
          bloc: () =>
              ListOfferBloc(di.sl<ListOfferRepository>())
                ..add(GetOffersEvent(merchantId: offerMerchantId)),
        );

      case Routes.offerDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final offerId = args?['offerId'] as String? ?? '';
        if (offerId.isEmpty) {
          return _buildRoute(
            Scaffold(body: Center(child: Text('Offer ID not provided'))),
            settings,
          );
        }
        return _buildRouteWithBlocs(
          OfferDetailsPage(offerId: offerId),
          settings,
          providers: [
            BlocProvider<OfferDetailsBloc>(
              create: (_) => OfferDetailsBloc(di.sl<OfferDetailsRepository>()),
            ),
            BlocProvider<ManageCartBloc>.value(value: di.sl<ManageCartBloc>()),
          ],
        );

      case Routes.favorites:
        {
          final favBloc = di.sl<FavoritesBloc>();
          favBloc.add(const LoadFavoritesEvent());
          return _buildRouteWithBlocValue<FavoritesBloc>(
            const FavoritesPage(),
            settings,
            bloc: favBloc,
          );
        }

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

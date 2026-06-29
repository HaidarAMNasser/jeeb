import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/pages/client_home_page.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeb_app/features/favorites/presentation/pages/favorites_page.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/pages/list_order_page.dart';
import 'package:jeeb_app/features/delivery/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/pages/basket_page.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/presentation/bloc/order_before_confirm_bloc.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_service.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';

abstract final class ClientNavigationTabs {
  ClientNavigationTabs._();

  static const int home = 0;
  static const int favorites = 1;
  static const int orders = 2;
  static const int basket = 3;

  static final ValueNotifier<int> selectedIndex = ValueNotifier<int>(home);

  static void switchTo(int index) {
    if (selectedIndex.value == index) return;
    selectedIndex.value = index;
  }

  static void switchToOrders() => switchTo(orders);

  static void switchToBasket() => switchTo(basket);

  /// Pops overlay routes back to the root shell and selects the basket tab.
  static void openBasketTab() {
    switchToBasket();
    NavigationService().navigationKey.currentState?.popUntil(
          (route) => route.isFirst,
        );
  }
}

class ClientNavigation extends StatefulWidget {
  const ClientNavigation({super.key});

  @override
  State<ClientNavigation> createState() => _ClientNavigationState();
}

class _ClientNavigationState extends State<ClientNavigation> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = ClientNavigationTabs.selectedIndex.value;
    ClientNavigationTabs.selectedIndex.addListener(_syncSelectedIndex);
  }

  @override
  void dispose() {
    ClientNavigationTabs.selectedIndex.removeListener(_syncSelectedIndex);
    super.dispose();
  }

  void _syncSelectedIndex() {
    final next = ClientNavigationTabs.selectedIndex.value;
    if (!mounted || next == _currentIndex) return;
    setState(() => _currentIndex = next);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return MultiBlocProvider(
          providers: [
            BlocProvider<FavoritesBloc>.value(value: di.sl<FavoritesBloc>()),
            BlocProvider<ClientHomeBloc>(
              create: (_) => di.sl<ClientHomeBloc>(),
            ),
            BlocProvider<ProfileBloc>.value(value: di.sl<ProfileBloc>()),
          ],
          child: const ClientHomePage(),
        );
      case 1:
        return BlocProvider<FavoritesBloc>.value(
          value: di.sl<FavoritesBloc>()..add(const LoadFavoritesEvent()),
          child: const FavoritesPage(removeBack: true),
        );
      case 2:
        return BlocProvider<ListOrderBloc>(
          create: (_) => di.sl<ListOrderBloc>()..add(const GetOrdersEvent()),
          child: const ListOrderPage(removeBack: true),
        );
      case 3:
        return MultiBlocProvider(
          providers: [
            BlocProvider<ListCartBloc>.value(
              value: di.sl<ListCartBloc>()..add(const LoadCartEvent()),
            ),
            BlocProvider<OrderBeforeConfirmBloc>(
              create: (_) => di.sl<OrderBeforeConfirmBloc>(),
            ),
          ],
          child: const BasketPage(removeBack: true),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != ClientNavigationTabs.home) {
          ClientNavigationTabs.switchTo(ClientNavigationTabs.home);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: ColorManager.background,
        body: _buildScreen(_currentIndex),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: ColorManager.primaryDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              ClientNavigationTabs.switchTo(index);
            },
            backgroundColor: ColorManager.primaryDark,
            selectedItemColor: ColorManager.primary,
            unselectedItemColor: ColorManager.textSecondary,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s12,
              color: ColorManager.primary,
            ),
            unselectedLabelStyle: getRegularStyle(
              fontSize: AppFontSize.s12,
              color: ColorManager.textSecondary,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: AppTranslation.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.favorite_outlined),
                activeIcon: const Icon(Icons.favorite),
                label: AppTranslation.favorites,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.assignment_outlined),
                activeIcon: const Icon(Icons.assignment),
                label: AppTranslation.orders,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_basket_outlined),
                activeIcon: const Icon(Icons.shopping_basket),
                label: AppTranslation.basket,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

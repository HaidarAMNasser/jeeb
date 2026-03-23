import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:jeeb_app/features/order/list_order/presentation/pages/list_order_page.dart';
import 'package:jeeb_app/features/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/basket/presentation/pages/basket_page.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';

class ClientNavigation extends StatefulWidget {
  const ClientNavigation({super.key});

  @override
  State<ClientNavigation> createState() => _ClientNavigationState();
}

class _ClientNavigationState extends State<ClientNavigation> {
  int _currentIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return MultiBlocProvider(
          providers: [
            BlocProvider<FavoritesBloc>.value(value: di.sl<FavoritesBloc>()),
            BlocProvider<ClientHomeBloc>(
              create: (_) => di.sl<ClientHomeBloc>(),
            ),
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()..add(const GetProfile()),
            ),
          ],
          child: const ClientHomePage(),
        );
      case 1:
        return BlocProvider<FavoritesBloc>.value(
          value: di.sl<FavoritesBloc>()..add(const LoadFavoritesEvent()),
          child: const FavoritesPage(),
        );
      case 2:
        return BlocProvider<ListOrderBloc>(
          create: (_) => di.sl<ListOrderBloc>()..add(const GetOrdersEvent()),
          child: const ListOrderPage(),
        );
      case 3:
        return const BasketPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onTap: (index) => setState(() => _currentIndex = index),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/auth/profile/presentation/pages/profile_page.dart';
import 'package:jeeb_app/features/auth/logout/presentation/bloc/logout_bloc.dart';
import 'package:jeeb_app/features/order/list_order/presentation/pages/list_order_page.dart';
import 'package:jeeb_app/features/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/pages/list_merchant_page.dart';
import 'package:jeeb_app/features/merchant/list_merchant/presentation/bloc/list_merchant_bloc.dart';
import 'package:jeeb_app/features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import 'package:jeeb_app/features/offers/presentation/pages/offers_page.dart';
import 'package:jeeb_app/features/offers/presentation/bloc/offers_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

class DriverNavigation extends StatefulWidget {
  const DriverNavigation({super.key});

  @override
  State<DriverNavigation> createState() => _DriverNavigationState();
}

class _DriverNavigationState extends State<DriverNavigation> {
  int _currentIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return BlocProvider<ListMerchantBloc>(
          create: (_) =>
              ListMerchantBloc(di.sl<ListMerchantRepository>())
                ..add(const GetMerchantsEvent()),
          child: const ListMerchantPage(),
        );
      case 1:
        return BlocProvider<OffersBloc>(
          create: (_) => di.sl<OffersBloc>(),
          child: const OffersPage(),
        );
      case 2:
        return BlocProvider<ListOrderBloc>(
          create: (_) => di.sl<ListOrderBloc>()..add(const GetOrdersEvent()),
          child: const ListOrderPage(),
        );
      case 3:
        return MultiBlocProvider(
          providers: [
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()..add(const GetProfile()),
            ),
            BlocProvider<LogoutBloc>(create: (_) => di.sl<LogoutBloc>()),
          ],
          child: const ProfilePage(),
        );
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
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
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: AppTranslation.merchants,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: 'Offers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: AppTranslation.orders,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppTranslation.profile,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/features/auth/logout/presentation/bloc/logout_bloc.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/auth/profile/presentation/pages/profile_page.dart';
import 'package:jeeb_app/features/offer/list_offer/data/repositories/list_offer_repository.dart';
import 'package:jeeb_app/features/offer/list_offer/presentation/bloc/list_offer_bloc.dart';
import 'package:jeeb_app/features/offer/list_offer/presentation/pages/list_offer_page.dart';
import 'package:jeeb_app/features/order/list_order/presentation/bloc/list_order_bloc.dart';
import 'package:jeeb_app/features/order/list_order/presentation/pages/list_order_page.dart';
import 'package:jeeb_app/features/product/list_product/data/repositories/list_product_repository.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';
import 'package:jeeb_app/features/product/list_product/presentation/pages/list_product_page.dart';

class MerchantNavigation extends StatefulWidget {
  const MerchantNavigation({super.key});

  @override
  State<MerchantNavigation> createState() => _MerchantNavigationState();
}

class _MerchantNavigationState extends State<MerchantNavigation> {
  int _currentIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return BlocProvider<ListProductBloc>(
          create: (_) => ListProductBloc(di.sl<ListProductRepository>())
            ..add(const GetProductsEvent()),
          child: const ListProductPage(),
        );
      case 1:
        return BlocProvider<ListOfferBloc>(
          create: (_) => ListOfferBloc(di.sl<ListOfferRepository>())
            ..add(const GetOffersEvent()),
          child: const ListOfferPage(),
        );
      case 2:
        return BlocProvider<ListOrderBloc>(
          create: (_) => di.sl<ListOrderBloc>()
            ..add(const GetOrdersEvent()),
          child: const ListOrderPage(),
        );
      case 3:
        return MultiBlocProvider(
          providers: [
            BlocProvider<ProfileBloc>(
              create: (_) => di.sl<ProfileBloc>()..add(const GetProfile()),
            ),
            BlocProvider<LogoutBloc>(
              create: (_) => di.sl<LogoutBloc>(),
            ),
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
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: AppTranslation.products,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_offer_outlined),
              activeIcon: Icon(Icons.local_offer),
              label: AppTranslation.offers,
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


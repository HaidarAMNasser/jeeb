import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/pages/delivery_home_page.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_persistent_tracking_scope.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/presentation/bloc/manage_order_bloc.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_orders/screens/delivery_orders_page.dart';
import 'package:jeeb_app/features/auth/profile/presentation/pages/profile_page.dart';
import 'package:jeeb_app/features/auth/logout/presentation/bloc/logout_bloc.dart';

class DeliveryNavigation extends StatefulWidget {
  const DeliveryNavigation({super.key});

  @override
  State<DeliveryNavigation> createState() => _DeliveryNavigationState();
}

class _DeliveryNavigationState extends State<DeliveryNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManageOrderBloc>.value(
      value: di.sl<ManageOrderBloc>(),
      child: BlocProvider<DeliveryHomeBloc>.value(
        value: di.sl<DeliveryHomeBloc>(),
        child: DeliveryPersistentTrackingScope(
          child: Scaffold(
            backgroundColor: ColorManager.background,
            body: IndexedStack(
              index: _currentIndex,
              children: [
                const DeliveryHomePage(),
                const DeliveryOrdersPage(),
                BlocProvider<LogoutBloc>(
                  create: (_) => di.sl<LogoutBloc>(),
                  child: const ProfilePage(),
                ),
              ],
            ),
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
                    icon: const Icon(Icons.local_shipping_outlined),
                    activeIcon: const Icon(Icons.local_shipping),
                    label: AppTranslation.myOrders,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person_outline),
                    activeIcon: const Icon(Icons.person),
                    label: AppTranslation.profile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

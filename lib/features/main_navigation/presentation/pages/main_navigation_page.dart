import 'package:flutter/material.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/features/auth/profile/presentation/bloc/profile_bloc.dart';
import 'package:jeeb_app/features/main_navigation/presentation/pages/client_navigation.dart';
import 'package:jeeb_app/features/main_navigation/presentation/pages/delivery_navigation.dart';

import '../../../../core/infrastructure/di/dependency_injection.dart' as di;
import '../../../../core/common/classes/user_roles.dart';
import '../../../../core/presentation/routes/routes.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final storageService = di.sl<StorageService>();
    final role = await storageService.getUserRole();
    setState(() {
      _userRole = role;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      di.sl<ProfileBloc>().add(const GetProfile());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorManager.background,
        body: Center(
          child: CircularProgressIndicator(color: ColorManager.primary),
        ),
      );
    }

    // Route based on user role

    if (_userRole == UserRoles.deliveryMan.name ||
        _userRole?.toUpperCase() == 'DELIVERY') {
      return const DeliveryNavigation();
    } else if (_userRole == UserRoles.customer.name ||
        _userRole?.toUpperCase() == 'CUSTOMER') {
      return const ClientNavigation();
    } else {
      // If no role found or unsupported role, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(Routes.login);
      });
      return Scaffold(
        backgroundColor: ColorManager.background,
        body: Center(
          child: CircularProgressIndicator(color: ColorManager.primary),
        ),
      );
    }
  }
}

class SpecialRoutes {
  String hnadleRoutes(String remeeredMe, String isGuest) {
    if (isGuest == "true") {
      return Routes.login;
    }
    if (remeeredMe == "true") {
      return Routes.home;
    }
    return Routes.login;
  }
}

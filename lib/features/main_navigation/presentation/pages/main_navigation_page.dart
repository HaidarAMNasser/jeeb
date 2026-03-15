import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_cubit.dart';
import 'package:jeeb_app/features/client_home/presentation/pages/client_home_page.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeb_app/features/main_navigation/presentation/pages/admin_navigation.dart';
import 'package:jeeb_app/features/main_navigation/presentation/pages/merchant_navigation.dart';

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

    // Route based on user role (ConfirmProductBloc only provided for admin flow via routes)
    if (_userRole == UserRoles.merchant.name) {
      return const MerchantNavigation();
    } else if (_userRole == UserRoles.admin.name) {
      return const AdminNavigation();
    } else if (_userRole == UserRoles.customer.name ||
        _userRole?.toUpperCase() == 'CUSTOMER') {
      return BlocProvider<FavoritesBloc>.value(
        value: di.sl<FavoritesBloc>(),
        child: BlocProvider(
          create: (_) => di.sl<ClientHomeCubit>(),
          child: const ClientHomePage(),
        ),
      );
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

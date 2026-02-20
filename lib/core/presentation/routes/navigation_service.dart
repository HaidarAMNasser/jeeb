import 'package:flutter/material.dart';

/// Navigation Service
/// Provides centralized navigation management
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  NavigationService._internal();

  factory NavigationService() => _instance;

  final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

  back([dynamic popValue]) {
    try {
      if (navigationKey.currentState != null &&
          navigationKey.currentState!.mounted &&
          navigationKey.currentContext != null) {
        return navigationKey.currentState!.pop(popValue);
      }
    } catch (e) {
      // Handle navigation errors gracefully
      print('Navigation error in back(): $e');
    }
    return null;
  }

  push(Widget page, {arguments}) {
    try {
      if (navigationKey.currentState != null &&
          navigationKey.currentState!.mounted &&
          navigationKey.currentContext != null) {
        return navigationKey.currentState!.push(
          MaterialPageRoute(builder: (_) => page),
        );
      }
    } catch (e) {
      // Handle navigation errors gracefully
      print('Navigation error in push(): $e');
    }
    return null;
  }

  pushReplacement(Widget page, {arguments}) {
    try {
      if (navigationKey.currentState != null &&
          navigationKey.currentState!.mounted &&
          navigationKey.currentContext != null) {
        return navigationKey.currentState!.pushReplacement(
          MaterialPageRoute(builder: (_) => page),
        );
      }
    } catch (e) {
      // Handle navigation errors gracefully
      print('Navigation error in pushReplacement(): $e');
    }
    return null;
  }

  pushNamed(String routeName, {Object? arguments}) {
    try {
      if (navigationKey.currentState != null &&
          navigationKey.currentState!.mounted &&
          navigationKey.currentContext != null) {
        return navigationKey.currentState!.pushNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e) {
      // Handle navigation errors gracefully
      print('Navigation error in pushNamed(): $e');
    }
    return null;
  }

  pushReplacementNamed(String routeName, {Object? arguments}) {
    try {
      if (navigationKey.currentState != null &&
          navigationKey.currentState!.mounted) {
        return navigationKey.currentState!.pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e) {
      // Handle navigation errors gracefully
      print('Navigation error in pushReplacementNamed(): $e');
    }
    return null;
  }

  pushNamedAndRemoveUntil(String routeName, {Object? arguments}) {
    try {
      if (navigationKey.currentState != null &&
          navigationKey.currentState!.mounted &&
          navigationKey.currentContext != null) {
        return navigationKey.currentState!.pushNamedAndRemoveUntil(
          routeName,
          arguments: arguments,
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Handle navigation errors gracefully
      print('Navigation error in pushNamedAndRemoveUntil(): $e');
    }
    return null;
  }

  void popUntil() {
    try {
      if (navigationKey.currentState != null &&
          navigationKey.currentState!.mounted &&
          navigationKey.currentContext != null) {
        navigationKey.currentState!.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Handle navigation errors gracefully
      print('Navigation error in popUntil(): $e');
    }
  }
}

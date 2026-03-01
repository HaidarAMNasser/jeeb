import 'package:flutter/material.dart';

extension NavigationExtensions on BuildContext {
  Future<T?> pushNamed<T extends Object?>(String routeName,
      {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  void pushNamedAndRemoveUntil(
    String routeName, {
    required bool Function(Route<dynamic> route) predicate,
  }) {
    Navigator.of(this).pushNamedAndRemoveUntil(routeName, predicate);
  }
}

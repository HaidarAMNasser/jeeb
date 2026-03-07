import 'package:flutter/material.dart';

extension Navigation on BuildContext {
  pushNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  pushReplacementNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  pushNamedAndRemoveUntil(String routeName,
      {Object? arguments, required RoutePredicate predicate}) {
    return Navigator.of(this)
        .pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments);
  }

  void pop({Object? arguments}) {
    if (Navigator.of(this).mounted) {
      Navigator.of(this).pop(arguments);
    }
  }
  bool canPop() => Navigator.of(this).mounted && Navigator.of(this).canPop();
}

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';

void customToast({
  required String msg,
  Toast toastLength = Toast.LENGTH_SHORT,
  double? fontSize,
  ToastGravity gravity = ToastGravity.BOTTOM,
  Color? backgroundColor,
  Color? textColor,
}) => Fluttertoast.showToast(
  msg: msg,
  toastLength: toastLength,
  fontSize: fontSize ?? AppFontSize.s14,
  backgroundColor: backgroundColor,
  gravity: gravity,
  textColor: textColor,
);

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'font_manager.dart';

TextStyle _getTextStyle({
  double? fontSize,
  Color color = ColorManager.textColor,
  Color? backgroundColor,
  String? fontFamily,
  TextDecoration textDecoration = TextDecoration.none,
  FontWeight fontWeight = FontWeightManager.light,
}) {
  return TextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    decoration: textDecoration,
    fontFamily: fontFamily ?? FontConstant.fontTajwal,
    decorationColor: color,
    backgroundColor: backgroundColor,
    fontWeight: fontWeight,
  );
}

TextStyle getRegularStyle({
  String? fontFamily,
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.regular,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
    fontFamily: fontFamily ?? FontConstant.fontTajwal,
  );
}

TextStyle getMediumStyle({
  String? fontFamily,
  int? maxlines,
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.medium,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
    fontFamily: fontFamily ?? FontConstant.fontTajwal,
  );
}

TextStyle getSemiBoldStyle({
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.semiBold,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
  );
}

TextStyle getBoldStyle({
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
  String? fontFamily,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.bold,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
    fontFamily: fontFamily ?? FontConstant.fontTajwal,
  );
}

TextStyle getExtraBoldStyle({
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.extraBold,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
  );
}

TextStyle getLightStyle({
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.light,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
  );
}

TextStyle getExtraLightStyle({
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.extraLight,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
  );
}

TextStyle getBlackStyle({
  double? fontSize,
  Color color = ColorManager.textColor,
  TextDecoration textDecoration = TextDecoration.none,
  Color? backgroundColor,
}) {
  return _getTextStyle(
    fontSize: fontSize ?? AppFontSize.s14,
    color: color,
    fontWeight: FontWeightManager.black,
    textDecoration: textDecoration,
    backgroundColor: backgroundColor,
  );
}

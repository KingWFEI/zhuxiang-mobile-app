import 'package:flutter/material.dart';

class AppIcon {
  const AppIcon._();

  static const iconBack = Icon(Icons.arrow_back_ios_new, size: 16);
  static Icon iconNormal(IconData iconName, {Color? color}) {
    return Icon(iconName, size: 16, color: color);
  }
}

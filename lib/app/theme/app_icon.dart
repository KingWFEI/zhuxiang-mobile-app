import 'package:flutter/material.dart';

class AppIcon {
  const AppIcon._();

  static const iconBack = Icon(Icons.arrow_back_ios_new, size: 14);
  static Icon iconNormal(IconData iconName, {Color? color}) {
    return Icon(iconName, size: 14, color: color);
  }
}

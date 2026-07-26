import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF176B52);
  static const primaryDark = Color(0xFF0D3D32);
  static const primaryContainer = Color(0xFFDDF1E8);
  static const background = Color(0xFFFAF8F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5EF);
  static const textPrimary = Color(0xFF14251F);
  static const textSecondary = Color(0xFF65726C);
  static const excellent = Color(0xFF16845C);
  static const good = Color(0xFF1B7A78);
  static const mixed = Color(0xFFE08B2F);
  static const lessFavorable = Color(0xFFC7662E);
  static const poor = Color(0xFFB94B4B);
  static const unavailable = Color(0xFF7B8580);
}

class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  const AppRadius._();

  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
}

class AppShadows {
  const AppShadows._();

  static const soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
  ];
}

class AppTypography {
  const AppTypography._();

  static const fontFamily = String.fromEnvironment('APP_FONT_FAMILY');
}

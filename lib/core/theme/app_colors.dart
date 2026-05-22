import 'package:flutter/material.dart';

/// Design tokens from the CampusConnect spec (dark-first).
abstract final class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF00E5FF);
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD740);
  static const Color error = Color(0xFFFF5252);
  static const Color background = Color(0xFF0D0D1A);
  static const Color cardSurface = Color(0xFF1A1A2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C6);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const List<Color> meshGradient = [
    Color(0xFF6C63FF),
    Color(0xFF00E5FF),
    Color(0xFF0D0D1A),
  ];
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

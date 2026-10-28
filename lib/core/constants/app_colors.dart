import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF142B3B);
  static const Color mintTeal = Color(0xFF38DCC0);
  static const Color offWhite = Color(0xFFF4F7F8);
  static const Color surface = Colors.white;

  static const Color textPrimary = Color(0xFF142B3B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFCBD5E1);

  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color chipBackground = Color(0xFFF8FAFC);
  static const Color divider = Color(0xFFF1F5F9);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkChip = Color(0xFF24334A);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? darkBackground : offWhite;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color chipOf(BuildContext context) =>
      isDark(context) ? darkChip : chipBackground;

  static Color dividerOf(BuildContext context) =>
      isDark(context) ? darkBorder : divider;
}


import 'package:flutter/material.dart';

/// CleanCycle colour tokens, taken from the Milestone 02 high-fidelity screens.
///
/// Other team members should import this file instead of hard-coding hex values
/// so the whole app stays visually consistent.
class AppColors {
  AppColors._();

  /// Primary action colour (Login / Create Account / Verify buttons).
  static const Color primary = Color(0xFF2E7D32);

  /// Pressed / dark variant of [primary].
  static const Color primaryDark = Color(0xFF1B5E20);

  /// Soft fill used behind icons, badges and selected nav items.
  static const Color primarySoft = Color(0xFFE8F5E9);

  /// Leaf / logo accent.
  static const Color leaf = Color(0xFF43A047);

  /// App scaffold background (very light green-grey, not pure white).
  static const Color background = Color(0xFFF7FBF8);

  /// Cards, sheets and input fills sit on white.
  static const Color surface = Color(0xFFFFFFFF);

  /// Input field fill matching the Figma "soft grey" fields.
  static const Color inputFill = Color(0xFFF3F6F4);

  /// Default body text — high contrast on [background] / [surface].
  static const Color textPrimary = Color(0xFF1B1B1B);

  /// Labels, hints and secondary copy.
  static const Color textSecondary = Color(0xFF6B7280);

  /// Placeholder text inside fields.
  static const Color textHint = Color(0xFF9CA3AF);

  /// Links such as "Forgot Password?" and "Change Email".
  static const Color link = Color(0xFF2E7D32);

  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  static const Color error = Color(0xFFC62828);
  static const Color errorSoft = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);

  /// Password-strength meter stops.
  static const Color strengthWeak = Color(0xFFE53935);
  static const Color strengthMedium = Color(0xFFFB8C00);
  static const Color strengthStrong = Color(0xFF43A047);

  static const Color socialBorder = Color(0xFFE5E7EB);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color appleBlack = Color(0xFF111111);

  static const Color navInactive = Color(0xFF9CA3AF);
  static const Color overlayScrim = Color(0x66000000);
}

import 'package:flutter/material.dart';

class AppColors {
  static bool isDarkMode = true; // Default to Dark Mode as requested

  // Brand & Accent
  static Color _primary = const Color(0xFF0054FF);
  static Color get primary => _primary;
  static set primary(Color val) => _primary = val;

  static Color get primaryDeep {
    final hsl = HSLColor.fromColor(_primary);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  static Color get primarySoft => _primary.withOpacity(0.15);
  static const Color fbBlue = Color(0xFF1877F2);        // Facebook Blue - Selected form state
  static const Color metaLink = Color(0xFF0064E0);      // Meta Link Blue - Legacy link
  static const Color oculusPurple = Color(0xFF7014F2);  // Oculus Purple - VR category emphasis

  // Surface
  static Color get canvas => isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFFFFFFF);        // Page background
  static Color get surfaceSoft => isDarkMode ? const Color(0xFF172033) : const Color(0xFFF2F4F8);   // Thumbnail, rest state search
  static Color get hairline => isDarkMode ? const Color(0xFF26334D) : const Color(0xFFE4E6EB);      // 1px border
  static Color get hairlineSoft => isDarkMode ? const Color(0xFF1D283D) : const Color(0xFFF0F2F5);  // Card divider, section break

  // Text
  static Color get inkDeep => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF0A1317);       // Primary headline
  static Color get ink => isDarkMode ? const Color(0xFFE4E6EB) : const Color(0xFF1C2B33);           // Standard body, sub-headline
  static Color get charcoal => isDarkMode ? const Color(0xFF9FB0C0) : const Color(0xFF4B5A64);      // Tertiary text, button labels
  static Color get slate => isDarkMode ? const Color(0xFF8A9CAF) : const Color(0xFF657786);         // Section header copy
  static Color get steel => isDarkMode ? const Color(0xFF657786) : const Color(0xFF8D99AE);         // Caption, footer link
  static Color get stone => isDarkMode ? const Color(0xFF2A374E) : const Color(0xFFCCD6DD);         // Disabled labels

  // Semantic
  static const Color success = Color(0xFF00A400);       // Success - "In stock" green
  static const Color attention = Color(0xFFFFBA00);     // Attention - "Selling fast" amber
  static const Color warning = Color(0xFFF5C400);       // Warning - Banner promo yellow
  static const Color critical = Color(0xFFFA3E3E);      // Critical - Out of stock, error chips
  static const Color criticalStrong = Color(0xFFE0245E); // Critical Strong - Form error border
}

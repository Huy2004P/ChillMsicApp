import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  // Common text style base generator using Montserrat
  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double letterSpacing = 0.0,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.inkDeep,
    );
  }

  // Typography Tokens
  static TextStyle get heroDisplay => _base(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.16,
      );

  static TextStyle get displayLg => _base(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.17,
      );

  static TextStyle get headingLg => _base(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.28,
      );

  static TextStyle get headingMd => _base(
        fontSize: 18,
        fontWeight: FontWeight.w300, // Light editorial subhead
        height: 1.21,
      );

  static TextStyle get headingSm => _base(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.25,
      );

  static TextStyle get subtitleLg => _base(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.44,
      );

  static TextStyle get subtitleMd => _base(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.44,
      );

  static TextStyle get bodyMd => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.50,
        letterSpacing: -0.16,
        color: AppColors.ink,
      );

  static TextStyle get bodyMdBold => _base(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.50,
        letterSpacing: -0.16,
        color: AppColors.inkDeep,
      );

  static TextStyle get bodySm => _base(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: -0.14,
        color: AppColors.charcoal,
      );

  static TextStyle get bodySmBold => _base(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.43,
        letterSpacing: -0.14,
        color: AppColors.inkDeep,
      );

  static TextStyle get caption => _base(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: AppColors.steel,
      );

  static TextStyle get captionBold => _base(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.33,
        color: AppColors.inkDeep,
      );

  static TextStyle get buttonMd => _base(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.43,
        letterSpacing: -0.14,
      );

  static TextStyle get linkMd => _base(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.50,
        letterSpacing: -0.16,
        color: AppColors.metaLink,
      );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText {
  /// Base function for all text styles
  static TextStyle _base({
    FontWeight fontWeight = FontWeight.normal,
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.poppins(
      fontWeight: fontWeight,
      fontSize: fontSize ?? 14,
      color: color ?? Colors.black,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Light font
  static TextStyle light({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return _base(
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Normal font
  static TextStyle normal({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return _base(
      fontWeight: FontWeight.w500,
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  /// Bold font
  static TextStyle bold({
    double? fontSize,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return _base(
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }
}

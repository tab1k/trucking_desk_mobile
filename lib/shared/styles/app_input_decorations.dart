import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppInputDecorations {
  const AppInputDecorations._();

  static const Color _fillColor = Colors.white;
  static const Color _borderColor = Color(0xFFE1E6F5);
  static const Color _focusColor = Color(0xFF0E4ECF);

  static InputDecorationTheme theme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: _fillColor,
      hintStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.4),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18.r),
        borderSide: const BorderSide(color: _focusColor),
      ),
      floatingLabelStyle: const TextStyle(
        color: _focusColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static InputDecoration rounded({
    String? label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? prefix,
    Widget? suffix,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefix: prefix,
      suffix: suffix,
      contentPadding: contentPadding,
    ).applyDefaults(theme());
  }
}

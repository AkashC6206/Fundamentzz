import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        primaryContainer: AppColors.primaryBlueLight,
        secondary: AppColors.primaryBlueDark,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.accentNavy,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColors.accentNavy,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.accentNavy,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.accentNavy,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.accentNavy,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.accentNavy,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.accentNavy,
          fontSize: 14,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.accentNavy,
          fontSize: 13,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.secondaryText,
          fontSize: 12,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.accentNavy,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.accentNavy),
        titleTextStyle: TextStyle(
          color: AppColors.accentNavy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(double.infinity, AppDimens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

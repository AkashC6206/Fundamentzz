import 'package:flutter/material.dart';

/// App Color Palette matching Enterprise Fintech / POS Specifications
class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primaryBlue = Color(0xFF1E5FDE);       // Main CTAs, active nav, checkout
  static const Color primaryBlueDark = Color(0xFF0F3FA8);   // Gradient end, pressed states, headers
  static const Color primaryBlueLight = Color(0xFF4C8CFF);  // Hover states, highlights, chips
  static const Color accentNavy = Color(0xFF0A1E42);        // Primary text, icons, bold headings

  // Backgrounds & Neutrals
  static const Color background = Color(0xFFFFFFFF);        // White base
  static const Color canvas = Color(0xFFF5F7FA);            // App canvas, card background
  static const Color surface = Color(0xFFFFFFFF);           // Elevated surface
  static const Color border = Color(0xFFE2E6ED);             // Borders, separators
  static const Color secondaryText = Color(0xFF6B7280);     // Subtitles, timestamps, hints
  static const Color metallicSilver = Color(0xFFC7CCD4);    // Disabled states, subtle icons

  // Semantic Colors (POS / Billing Use)
  static const Color success = Color(0xFF1FAA59);          // Payment success, Paid tag
  static const Color warning = Color(0xFFF5A524);          // Pending invoices, low stock, hold bills
  static const Color danger = Color(0xFFE5484D);           // Failed transactions, out of stock, delete
  static const Color info = Color(0xFF0284C7);             // Info badges

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A1E42), Color(0xFF1E5FDE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF1FAA59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

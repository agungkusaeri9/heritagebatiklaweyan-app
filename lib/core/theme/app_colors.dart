import 'package:flutter/material.dart';

/// Palet warna elegan untuk aplikasi E-Commerce Heritage Batik & Toko Online
class AppColors {
  AppColors._();

  // Primary Brand Colors (Batik Sogan Brown)
  static const Color primary = Color(0xFF704F38);
  static const Color primaryDark = Color(0xFF4A3423);
  static const Color primaryLight = Color(0xFF8D674B);

  // Accent Colors (Batik Sogan Gold & Amber)
  static const Color accent = Color(0xFFD97706); // Warm Amber / Sogan Gold
  static const Color accentLight = Color(0xFFFDE68A);
  static const Color accentDark = Color(0xFFB45309);

  // Backgrounds & Surface
  static const Color bgPrimary = Color(0xFF704F38); // Background Primary (#704F38)
  static const Color backgroundPrimary = Color(0xFF704F38);
  static const Color background = Color(0xFF704F38); // Background Utama (#704F38)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Colors.white;

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Soft / Pastel Feedback Colors (Nyaman di mata & tidak menyala)
  static const Color errorLight = Color(0xFFFFF1F2); // Background merah pastel sangat soft (Rose-50)
  static const Color errorBorder = Color(0xFFFECDD3); // Border merah soft
  static const Color errorText = Color(0xFF9F1239); // Teks merah pekat elegan & mudah dibaca (Rose-900)
  static const Color errorIconBg = Color(0xFFFFE4E6); // Lingkaran icon merah soft

  static const Color successLight = Color(0xFFF0FDF4); // Background hijau pastel soft
  static const Color successBorder = Color(0xFFBBF7D0); // Border hijau soft
  static const Color successText = Color(0xFF166534); // Teks hijau pekat elegan
  static const Color successIconBg = Color(0xFFDCFCE7); // Lingkaran icon hijau soft

  static const Color infoLight = Color(0xFFEFF6FF); // Background biru pastel soft
  static const Color infoBorder = Color(0xFFBFDBFE); // Border biru soft
  static const Color infoText = Color(0xFF1E40AF); // Teks biru pekat
  static const Color infoIconBg = Color(0xFFDBEAFE); // Lingkaran icon biru soft

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFFD97706);
  static const Color divider = Color(0xFFEEF2F6);
}

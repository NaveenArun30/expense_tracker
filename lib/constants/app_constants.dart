import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> categories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Other',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Bills & Utilities': Icons.receipt_long,
    'Healthcare': Icons.medical_services,
    'Education': Icons.school,
    'Travel': Icons.flight,
    'Other': Icons.category,
  };

  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFFF6B6B),
    'Transportation': Color(0xFF4ECDC4),
    'Shopping': Color(0xFF45B7D1),
    'Entertainment': Color(0xFF96CEB4),
    'Bills & Utilities': Color(0xFFFD79A8),
    'Healthcare': Color(0xFFE17055),
    'Education': Color(0xFF74B9FF),
    'Travel': Color(0xFFFDCB6E),
    'Other': Color(0xFFA29BFE),
  };

  // Primary Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C94FF);
  static const Color primaryDark = Color(0xFF3D35CC);
  static const Color primaryVariant = Color(0xFF5A52E3);

  // Secondary Colors
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryLight = Color(0xFF66FFF9);
  static const Color secondaryDark = Color(0xFF00A896);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color black = Colors.black;

  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textTertiary = Color(0xFF718096);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color successColor = Color(0xFF20BF55);
  static const Color successLight = Color(0xFF68D391);
  static const Color successDark = Color(0xFF38A169);

  static const Color warningColor = Color(0xFFFDCB6E);
  static const Color warningLight = Color(0xFFFBD38D);
  static const Color warningDark = Color(0xFFED8936);

  static const Color errorColor = Color(0xFFFF5722);
  static const Color errorLight = Color(0xFFFF8A65);
  static const Color errorDark = Color(0xFFE64A19);

  static const Color infoColor = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF5A52E3),
  ];

  static const List<Color> balanceCardGradient = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
  ];

  static const List<Color> successGradient = [
    Color(0xFF20BF55),
    Color(0xFF01BAEF),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFDCB6E),
    Color(0xFFFC7E46),
  ];
}

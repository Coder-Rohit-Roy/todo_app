import 'package:flutter/material.dart';

class AppTheme {
  // Theme state
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // Dark Mode Colors
  static const Color darkBgStart = Color(0xFF0F172A); // Slate 900
  static const Color darkBgEnd = Color(0xFF1E1B4B);   // Indigo 950
  static const Color darkCardBg = Color(0x2A1E293B);  // Semi-transparent
  static const Color darkBorder = Color(0x3394A3B8);  // Slate 400 with opacity
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400

  // Light Mode Colors
  static const Color lightBgStart = Color(0xFFEEF2F6); 
  static const Color lightBgEnd = Color(0xFFE0E7FF);   // Indigo 50
  static const Color lightCardBg = Color(0x55FFFFFF); // Transparent White
  static const Color lightBorder = Color(0x40818CF8); // Indigo 400 with opacity
  static const Color lightTextPrimary = Color(0xFF1E293B); // Slate 800
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500

  // App Accents
  static const Color primaryAccent = Color(0xFF6366F1); // Indigo 500
  static const Color secondaryAccent = Color(0xFFEC4899); // Pink 500

  // Gradients for Categories
  static const LinearGradient workGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)], // Royal Blue to Cyan
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient studyGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)], // Violet to Magenta
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient personalGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)], // Amber to Red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getCategoryGradient(String category) {
    switch (category) {
      case 'Work':
        return workGradient;
      case 'Study':
        return studyGradient;
      case 'Personal':
      default:
        return personalGradient;
    }
  }

  // Gradients for Priorities
  static const LinearGradient priorityHigh = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)], // Crimson to Soft Red
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient priorityMedium = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Amber to Yellow
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient priorityLow = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)], // Emerald to Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getPriorityGradient(String priority) {
    switch (priority) {
      case 'High':
        return priorityHigh;
      case 'Medium':
        return priorityMedium;
      case 'Low':
      default:
        return priorityLow;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
      default:
        return const Color(0xFF10B981);
    }
  }

  // Beautiful Glassmorphic Box Decoration
  static BoxDecoration glassDecoration({
    required BuildContext context,
    double borderRadius = 16.0,
    bool isDarkMode = true,
  }) {
    return BoxDecoration(
      color: isDarkMode ? darkCardBg : lightCardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDarkMode ? darkBorder : lightBorder,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.indigo.withOpacity(0.05),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Linear background gradient
  static BoxDecoration backgroundDecoration(bool isDarkMode) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDarkMode 
            ? [darkBgStart, darkBgEnd]
            : [lightBgStart, lightBgEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}

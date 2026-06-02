import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5D57);
  static const Color primaryLight = Color(0xFF34B3A0);

  // Secondary Colors
  static const Color secondary = Color(0xFFE2954B);
  static const Color secondaryDark = Color(0xFFBF6E27);
  static const Color secondaryLight = Color(0xFFF2BE8B);

  // Accent Colors
  static const Color accent = Color(0xFFC96F4A);
  static const Color accentDark = Color(0xFFA85737);

  // Semantic Colors
  static const Color success = Color(0xFF57B26A);
  static const Color warning = Color(0xFFE0A126);
  static const Color error = Color(0xFFD95D5D);
  static const Color info = Color(0xFF4E95B8);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E2933);
  static const Color textSecondary = Color(0xFF6A7682);
  static const Color textHint = Color(0xFFB0B8C1);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Background Colors
  static const Color background = Color(0xFFF7F4EE);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1F2529);

  // Surface Colors
  static const Color surface = Color(0xFFFFFCF7);
  static const Color surfaceDark = Color(0xFF2A3237);
  static const Color surfaceMuted = Color(0xFFF1ECE4);

  // Border Colors
  static const Color border = Color(0xFFE3D9CD);
  static const Color borderDark = Color(0xFF48545B);

  // Difficulty Colors
  static const Color beginner = Color(0xFF63B46B);
  static const Color intermediate = Color(0xFFE0A126);
  static const Color advanced = Color(0xFFD95D5D);

  // Progress Colors
  static const Color progressComplete = success;
  static const Color progressInProgress = info;
  static const Color progressNotStarted = textHint;

  // Profile Accent Colors
  static const Color profileAccent = Color(0xFF6B7AA8);
  static const Color profileAccentLight = Color(0xFFDDE3F4);
  static const Color profileAccentBackground = Color(0xFFF3F6FC);
  static const Color profileCardBackground = Color(0xFFF8FAFD);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryDark, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x140F172A);
  static const Color shadowMedium = Color(0x260F172A);
  static const Color shadowDark = Color(0x4D000000);

  // Overlay Colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // Topic Colors
  static const Color categoryCommunication = Color(0xFF4E95B8);
  static const Color categoryFamily = Color(0xFFD97B8D);
  static const Color categoryFood = Color(0xFFE08B45);
  static const Color categoryCulture = Color(0xFF8D74C9);
  static const Color categoryNature = Color(0xFF63A86C);
  static const Color categoryProfessions = Color(0xFFC59B3A);

  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return beginner;
      case 'intermediate':
        return intermediate;
      case 'advanced':
        return advanced;
      default:
        return info;
    }
  }

  static Color getProgressColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return progressComplete;
      case 'inprogress':
      case 'in_progress':
        return progressInProgress;
      case 'notstarted':
      case 'not_started':
        return progressNotStarted;
      default:
        return info;
    }
  }
}

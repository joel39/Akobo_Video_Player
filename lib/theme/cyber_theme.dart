import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SFX Pack White & Blue Design System Tokens & Adaptive Theming
class CyberTheme {
  // Primary SFX Blue Palette (Image 2 - Ultimate SFX Pack)
  static const Color primaryBlue = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryBlueDark = Color(0xFF1D4ED8); // Deep Blue
  static const Color primaryBlueLight = Color(0xFF3B82F6); // Electric Blue Accent
  static const Color blueSoftTint = Color(0xFFEFF6FF); // Light Ice Blue
  static const Color blueGlow = Color(0xFF60A5FA); // Cyan-Blue Highlight
  static const Color royalFolderBlue = Color(0xFF2E72FB); // Folder Blue in Image 2

  // Light Mode Colors
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardGlass = Color(0xF2FFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardGlass = Color(0xE61E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // Legacy mappings for backwards-compatibility with existing widgets
  static const Color bgObsidian = darkBg;
  static const Color bgSurface = darkSurface;
  static const Color bgCard = darkCard;
  static const Color bgCardGlass = darkCardGlass;
  static const Color bgOverlay = Color(0xCC0B1120);

  static const Color neonCyan = primaryBlue;
  static const Color neonPurple = primaryBlueLight;
  static const Color neonPink = Color(0xFFF43F5E); // Accent coral/like
  static const Color neonGreen = Color(0xFF10B981); // Crisp emerald
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonRed = Color(0xFFEF4444);

  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textTertiary = darkTextTertiary;

  static const Color borderCyan = Color(0x332563EB);
  static const Color borderPurple = Color(0x333B82F6);

  // Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sfxCardGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cyanPurpleGradient = blueGradient;
  static const LinearGradient neonGreenGradient = blueGradient;
  static const LinearGradient amberPinkGradient = LinearGradient(
    colors: [neonAmber, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Adaptive Helpers
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getBg(BuildContext context) {
    return isDark(context) ? darkBg : lightBg;
  }

  static Color getSurface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color getCard(BuildContext context) {
    return isDark(context) ? darkCard : lightCard;
  }

  static Color getCardGlass(BuildContext context) {
    return isDark(context) ? darkCardGlass : lightCardGlass;
  }

  static Color getBorder(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color getTextTertiary(BuildContext context) {
    return isDark(context) ? darkTextTertiary : lightTextTertiary;
  }

  // Typography
  static TextStyle hudTitle({double size = 18, Color? color, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? primaryBlue,
      letterSpacing: -0.2,
    );
  }

  static TextStyle hudBadge({double size = 11, Color? color, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? primaryBlue,
      letterSpacing: 0.2,
    );
  }

  static TextStyle body({double size = 14, Color? color, FontWeight weight = FontWeight.w400}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? darkTextPrimary,
    );
  }

  static TextStyle bodyBold({double size = 14, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color ?? darkTextPrimary,
    );
  }

  static TextStyle mono({double size = 13, Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? primaryBlue,
    );
  }

  // Box Decorations
  static BoxDecoration glassCard({
    Color? borderColor,
    double borderRadius = 16,
    Color? bgColor,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: bgColor ?? darkCardGlass,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? darkBorder, width: 1.0),
      boxShadow: shadows ?? [
        BoxShadow(
          color: primaryBlue.withValues(alpha: 0.08),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static BoxDecoration adaptiveCard(
    BuildContext context, {
    double borderRadius = 16,
    Color? borderColor,
    Color? customBg,
  }) {
    final dark = isDark(context);
    return BoxDecoration(
      color: customBg ?? (dark ? darkCard : lightCard),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? (dark ? darkBorder : lightBorder),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: dark ? Colors.black.withValues(alpha: 0.25) : primaryBlue.withValues(alpha: 0.05),
          blurRadius: dark ? 12 : 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration neonPill({
    bool active = false,
    Color activeColor = primaryBlue,
    double radius = 24,
  }) {
    return BoxDecoration(
      color: active ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: active ? activeColor : darkBorder,
        width: active ? 1.4 : 1.0,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 0.5,
              ),
            ]
          : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class AppThemes {
  // Light Theme Configuration
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),

    // Background colors
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    cardColor: const Color(0xFFFFFFFF),

    // App Bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: null, // Let system handle overlay style
    ),

    // Text theme with consistent font families
    textTheme: _buildTextTheme(Brightness.light),

    // Primary text style
    primaryTextTheme: _buildTextTheme(Brightness.light),

    // Card theme
    cardTheme: CardTheme(
      color: const Color(0xFFFFFFFF),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: const Color(0xFF000000).withOpacity(0.04),
    ),

    // List tile theme
    listTileTheme: const ListTileThemeData(
      tileColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF111827),
      iconColor: Color(0xFF6B7280),
    ),

    // Cupertino overrides for iOS consistency
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: CupertinoColors.systemBlue,
      scaffoldBackgroundColor: Color(0xFFF2F2F7),
      barBackgroundColor: Color(0xFFFFFFFF),
      textTheme: CupertinoTextThemeData(),
    ),
  );

  // Dark Theme Configuration
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),

    // Background colors
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),

    // App Bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: null, // Let system handle overlay style
    ),

    // Text theme with consistent font families
    textTheme: _buildTextTheme(Brightness.dark),

    // Primary text style
    primaryTextTheme: _buildTextTheme(Brightness.dark),

    // Card theme
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: const Color(0xFF000000).withOpacity(0.3),
    ),

    // List tile theme
    listTileTheme: const ListTileThemeData(
      tileColor: Color(0xFF1E1E1E),
      textColor: Color(0xFFE5E7EB),
      iconColor: Color(0xFF9CA3AF),
    ),

    // Cupertino overrides for iOS consistency
    cupertinoOverrideTheme: const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: CupertinoColors.systemBlue,
      scaffoldBackgroundColor: Color(0xFF000000),
      barBackgroundColor: Color(0xFF1C1C1E),
      textTheme: CupertinoTextThemeData(),
    ),
  );

  /// Build text theme with platform-specific font families
  static TextTheme _buildTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light ? const Color(0xFF111827) : const Color(0xFFE5E7EB);

    final fontFamily = _getPlatformFontFamily();

    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
        decoration: TextDecoration.none,
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        decoration: TextDecoration.none,
      ),

      // Title styles
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        decoration: TextDecoration.none,
      ),

      // Body styles (most commonly used)
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        decoration: TextDecoration.none,
      ),

      // Label styles
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        decoration: TextDecoration.none,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
        decoration: TextDecoration.none,
      ),
    );
  }

  /// Get platform-specific font family
  static String _getPlatformFontFamily() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'SF Pro Display';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Roboto';
    }
    return 'system-ui';
  }

  /// Get theme-aware colors for custom components
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? const Color(0xFFFAFAFA) : const Color(0xFF121212);
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF1E1E1E);
  }

  static Color getPrimaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? const Color(0xFF111827) : const Color(0xFFE5E7EB);
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? const Color(0xFFE5E7EB) : const Color(0xFF374151);
  }

  /// Get a slightly darker background for buttons in dark mode for better visibility
  static Color getButtonBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFF9FAFB) // Very light gray for light mode
        : const Color(0xFF2D2D2D); // Darker gray for dark mode
  }

  /// Neumorphic colors for iOS-style design
  static Color getNeumorphicBackgroundColor(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Theme.of(context).brightness == Brightness.light ? const Color(0xFFEFEFEF) : const Color(0xFF2C2C2E);
    }
    return getCardColor(context);
  }

  static List<BoxShadow> getNeumorphicShadows(BuildContext context, {bool isPressed = false}) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return [
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.3),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ];
    }

    if (Theme.of(context).brightness == Brightness.light) {
      return isPressed
          ? [
              BoxShadow(
                color: const Color(0xFFD1D1D1).withOpacity(0.7),
                offset: const Offset(3, 3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFFFFF).withOpacity(0.8),
                offset: const Offset(-3, -3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ]
          : [
              BoxShadow(
                color: const Color(0xFFD1D1D1).withOpacity(0.7),
                offset: const Offset(6, 6),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFFFFF).withOpacity(0.8),
                offset: const Offset(-6, -6),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ];
    } else {
      return isPressed
          ? [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.5),
                offset: const Offset(3, 3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF404040).withOpacity(0.3),
                offset: const Offset(-3, -3),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ]
          : [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.5),
                offset: const Offset(6, 6),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF404040).withOpacity(0.3),
                offset: const Offset(-6, -6),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ];
    }
  }

  /// Get theme-aware badge gradient colors for neumorphic effect
  static List<Color> getNeumorphicBadgeColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return [
        const Color(0xFF2A2A2A),
        const Color(0xFF1E1E1E),
        const Color(0xFF1A1A1A),
      ];
    } else {
      return [
        const Color(0xFFDCDCE0),
        const Color(0xFFE4E4E7),
        const Color(0xFFECECEF),
      ];
    }
  }

  /// Get theme-aware badge shadows for neumorphic effect
  static List<BoxShadow> getNeumorphicBadgeShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return [
        // Dark shadow for subtle depth
        BoxShadow(
          color: const Color(0xFF000000).withOpacity(0.4),
          offset: const Offset(1, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
        // Light highlight for neumorphic effect
        BoxShadow(
          color: const Color(0xFF404040).withOpacity(0.3),
          offset: const Offset(-1, -1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
      ];
    } else {
      return [
        // Dark shadow for subtle depth
        BoxShadow(
          color: const Color(0xFFBEBFC4).withOpacity(0.4),
          offset: const Offset(1, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
        // Light highlight for neumorphic effect
        BoxShadow(
          color: const Color(0xFFFFFFFF).withOpacity(0.6),
          offset: const Offset(-1, -1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
      ];
    }
  }
}

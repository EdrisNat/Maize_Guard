import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern vibrant palette - Yellow & Green harmony
  static const _forest = Color(0xFF1B5E20);
  static const _leaf = Color(0xFF2E7D32);
  static const _freshGreen = Color(0xFF43A047);
  static const _sun = Color(0xFFFFD54F);
  static const _gold = Color(0xFFFFC107);
  static const _lightGold = Color(0xFFFFF8E1);
  static const _cream = Color(0xFFFFFDF5);
  static const _sage = Color(0xFFE8F5E9);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _leaf,
      brightness: Brightness.light,
    ).copyWith(
      primary: _leaf,
      onPrimary: Colors.white,
      secondary: _gold,
      onSecondary: const Color(0xFF1B1B1B),
      tertiary: _freshGreen,
      surface: _cream,
      surfaceContainerHighest: _sage,
      secondaryContainer: _lightGold,
      primaryContainer: const Color(0xFFC8E6C9),
      outline: const Color(0xFF81C784),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );

    return base.copyWith(
      scaffoldBackgroundColor: _cream,
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 40,
          fontWeight: FontWeight.w400,
          color: _forest,
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: _forest,
        ),
        headlineSmall: GoogleFonts.dmSerifDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: _forest,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: _forest,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2E4A32),
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF37474F),
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF546E7A),
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _forest,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _sage, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _forest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _forest,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _leaf,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _leaf,
          side: BorderSide(color: _leaf.withOpacity(0.3), width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: _forest,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _sage, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _sage, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _leaf, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.manrope(color: const Color(0xFF9E9E9E)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: _lightGold,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _forest,
            );
          }
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF78909C),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _forest, size: 24);
          }
          return const IconThemeData(color: Color(0xFF78909C), size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: _lightGold,
        disabledColor: Colors.grey.shade200,
        side: BorderSide(color: _sage, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF37474F),
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: _forest,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: _sage, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _gold,
        foregroundColor: _forest,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _forest,
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _leaf,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _freshGreen,
      onPrimary: Colors.white,
      secondary: _gold,
      onSecondary: const Color(0xFF1B1B1B),
      tertiary: _leaf,
      surface: const Color(0xFF121212),
      onSurface: const Color(0xFFE8E8E8),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      secondaryContainer: const Color(0xFF3D3D00),
      primaryContainer: const Color(0xFF1B4D1E),
      outline: const Color(0xFF4A7C50),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 40,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFE8E8E8),
          height: 1.1,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFE8E8E8),
        ),
        headlineSmall: GoogleFonts.dmSerifDisplay(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFE8E8E8),
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFE8E8E8),
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFD0D0D0),
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFCCCCCC),
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFAAAAAA),
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _freshGreen,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFE8E8E8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFE8E8E8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _freshGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _freshGreen,
          side: BorderSide(color: _freshGreen.withOpacity(0.4), width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: const Color(0xFF1B1B1B),
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF333333), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _freshGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: GoogleFonts.manrope(fontWeight: FontWeight.w500, color: const Color(0xFFAAAAAA)),
        hintStyle: GoogleFonts.manrope(color: const Color(0xFF666666)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        indicatorColor: const Color(0xFF3D3D00),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _gold,
            );
          }
          return GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF888888),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _gold, size: 24);
          }
          return const IconThemeData(color: Color(0xFF888888), size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedColor: const Color(0xFF3D3D00),
        disabledColor: const Color(0xFF2A2A2A),
        side: const BorderSide(color: Color(0xFF333333), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: const Color(0xFFCCCCCC),
        ),
        secondaryLabelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: _gold,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF333333), thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _gold,
        foregroundColor: const Color(0xFF1B1B1B),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        contentTextStyle: GoogleFonts.manrope(
          color: const Color(0xFFE8E8E8),
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _freshGreen;
          return const Color(0xFF888888);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _freshGreen.withOpacity(0.4);
          return const Color(0xFF333333);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFFE8E8E8),
        iconColor: Color(0xFFAAAAAA),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE8E8E8),
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  // Expose colors for direct access
  static const Color forest = _forest;
  static const Color leaf = _leaf;
  static const Color freshGreen = _freshGreen;
  static const Color sun = _sun;
  static const Color gold = _gold;
  static const Color lightGold = _lightGold;
  static const Color cream = _cream;
  static const Color sage = _sage;

  // Dark mode constants
  static const Color _darkSurface = Color(0xFF121212);
  static const Color _darkCard = Color(0xFF1E1E1E);
  static const Color _darkCardAlt = Color(0xFF2A2A2A);
  static const Color _darkBorder = Color(0xFF333333);
  static const Color _darkText = Color(0xFFE8E8E8);
  static const Color _darkTextSecondary = Color(0xFFAAAAAA);
  static const Color _darkAccentContainer = Color(0xFF3D3D00);
  static const Color _darkPrimaryContainer = Color(0xFF1B4D1E);

  // Theme-aware color getters
  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkCard : Colors.white;
  }

  static Color cardAltColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkCardAlt : const Color(0xFFF9FBF6);
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkBorder : _sage;
  }

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkSurface : _cream;
  }

  static Color accentContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkAccentContainer : _lightGold;
  }

  static Color primaryContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkPrimaryContainer : _sage;
  }

  static Color accentTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _gold : _forest;
  }

  static Color primaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkText : _forest;
  }

  static Color secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _darkTextSecondary : const Color(0xFF546E7A);
  }

  static Color iconOnAccentColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? _gold : _forest;
  }

  static LinearGradient backgroundGradient(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const LinearGradient(
        colors: [_darkSurface, _darkSurface],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return const LinearGradient(
      colors: [_lightGold, _cream, _sage],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  static LinearGradient cardGradient(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const LinearGradient(
        colors: [Color(0xFF1A3D1C), Color(0xFF2D5A30)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [_leaf, _freshGreen],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color alertBadgeColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF4A3D20) 
        : const Color(0xFFFFF1CC);
  }

  static Color alertIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFD4A84B) 
        : const Color(0xFF8C5A33);
  }

  static Color imagePlaceholderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF2A3D2A) 
        : const Color(0xFFE3EED9);
  }
}


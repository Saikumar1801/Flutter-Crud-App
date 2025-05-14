import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.teal,
    primaryColor: Colors.teal,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
      primary: Colors.teal.shade600,
      onPrimary: Colors.white,
      primaryContainer: Colors.teal.shade100,
      onPrimaryContainer: Colors.teal.shade900,
      secondary: Colors.cyan.shade600,
      onSecondary: Colors.white,
      secondaryContainer: Colors.cyan.shade100,
      onSecondaryContainer: Colors.cyan.shade900,
      error: Colors.red.shade700,
      onError: Colors.white,
      errorContainer: Colors.red.shade100,
      onErrorContainer: Colors.red.shade900,
      background: Colors.grey.shade100,
      onBackground: Colors.black87,
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceVariant: Colors.teal.shade50,
      onSurfaceVariant: Colors.black87,
      outline: Colors.grey.shade400,
      shadow: Colors.black26,
      inverseSurface: Colors.grey.shade800,
      onInverseSurface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.teal.shade600,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardTheme(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.teal.shade50,
      labelStyle: TextStyle(color: Colors.teal.shade800, fontSize: 11),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.teal.shade700,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.teal.shade400, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade500,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600)
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.teal.shade700,
      )
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: Colors.grey.shade800),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) return Colors.teal;
        return null;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
    ),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    primaryColor: Colors.tealAccent.shade200,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
      primary: Colors.tealAccent.shade200,
      onPrimary: Colors.black,
      primaryContainer: Colors.teal.shade800,
      onPrimaryContainer: Colors.tealAccent.shade100,
      secondary: Colors.cyanAccent.shade200,
      onSecondary: Colors.black,
      secondaryContainer: Colors.cyan.shade800,
      onSecondaryContainer: Colors.cyanAccent.shade100,
      error: Colors.redAccent.shade100,
      onError: Colors.black,
      errorContainer: Colors.red.shade900,
      onErrorContainer: Colors.redAccent.shade100,
      background: Colors.grey.shade900,
      onBackground: Colors.white70,
      surface: Colors.grey.shade800,
      onSurface: Colors.white70,
      surfaceVariant: Colors.grey.shade700,
      onSurfaceVariant: Colors.white70,
      outline: Colors.grey.shade600,
      shadow: Colors.black38,
      inverseSurface: Colors.grey.shade200,
      onInverseSurface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade800, // Corrected: Was shade850
      foregroundColor: Colors.tealAccent.shade100,
      elevation: 2,
    ),
    cardTheme: CardTheme(
      elevation: 2, // Adjusted from 3 for consistency if desired
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.teal.shade700,
      labelStyle: TextStyle(color: Colors.tealAccent.shade100, fontSize: 11),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.tealAccent.shade400,
      foregroundColor: Colors.black,
      elevation: 4,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800, // Corrected: Was shade850
      hintStyle: TextStyle(color: Colors.grey.shade500), // Corrected: Was 600
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade600),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.tealAccent.shade100, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    ),
     elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.tealAccent.shade400,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600)
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.tealAccent.shade200,
      )
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.grey[700],
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: Colors.white70),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) return Colors.tealAccent[200];
        return Colors.grey[600];
      }),
      checkColor: MaterialStateProperty.all(Colors.black),
      side: MaterialStateBorderSide.resolveWith(
        (states) => BorderSide(width: 1.5, color: states.contains(MaterialState.selected) ? Colors.tealAccent[200]! : Colors.grey[500]!),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade700,
      thickness: 1,
    ),
    useMaterial3: true,
  );
}
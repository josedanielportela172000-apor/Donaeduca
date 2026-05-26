import &#39;package:flutter/material.dart&#39;;
import &#39;package:google_fonts/google_fonts.dart&#39;;
class AppColors {
static const primary = Color(0xFF1a7a4a);
static const secondary = Color(0xFF2db368);
static const accent = Color(0xFFf5c842);
static const background = Color(0xFFfaf6ee);
static const dark = Color(0xFF0f1a12);
static const grey = Color(0xFF5a6b5e);
static const error = Color(0xFFe05c2a);
}
class AppTheme {
static ThemeData get theme =&gt; ThemeData(
primaryColor: AppColors.primary,
scaffoldBackgroundColor: AppColors.background,
colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
textTheme: GoogleFonts.dmSansTextTheme(),
appBarTheme: const AppBarTheme(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
elevation: 0,
),
elevatedButtonTheme: ElevatedButtonThemeData(
style: ElevatedButton.styleFrom(

backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(30)),
padding: const EdgeInsets.symmetric(vertical: 14),
),
),
inputDecorationTheme: InputDecorationTheme(
filled: true, fillColor: Colors.white,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: AppColors.grey)),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(
color: AppColors.primary, width: 2)),
),
);
}
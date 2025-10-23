import 'package:customer/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Styles {
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;
    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    final primarySwatch = createMaterialColor(isDarkTheme ? AppColors.darkModePrimary : AppColors.primary);
    return ThemeData(
      primarySwatch: primarySwatch,
      useMaterial3: false,
      colorScheme: ColorScheme(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primary: isDarkTheme ? AppColors.darkModePrimary : AppColors.primary,
        onPrimary: Colors.white,
        secondary: isDarkTheme ? AppColors.darkGray : AppColors.lightGray,
        onSecondary: Colors.black,
        error: Colors.red,
        onError: Colors.white,
        background: isDarkTheme ? AppColors.darkBackground : AppColors.background,
        onBackground: isDarkTheme ? Colors.white : Colors.black,
        surface: isDarkTheme ? AppColors.darkContainerBackground : AppColors.containerBackground,
        onSurface: isDarkTheme ? Colors.white : Colors.black,
      ),
      scaffoldBackgroundColor: isDarkTheme ? AppColors.darkBackground : AppColors.background,
      primaryColor: isDarkTheme ? AppColors.darkModePrimary : AppColors.primary,
      hintColor: isDarkTheme ? Colors.white38 : Colors.black38,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      buttonTheme: ButtonThemeData(
        textTheme: ButtonTextTheme.primary,
        colorScheme: ColorScheme.light(primary: isDarkTheme ? AppColors.darkModePrimary : AppColors.primary),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: isDarkTheme ? AppColors.darkBackground : AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        Theme.of(context).textTheme.apply(
          bodyColor: isDarkTheme ? Colors.white : Colors.black,
          displayColor: isDarkTheme ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  static Color getLoaderIndicatorColor(bool isDarkTheme) {
    // Always return a color that contrasts with teal
    return Colors.white;
  }

  static Color getLoaderMaskColor(bool isDarkTheme) {
    // Subtle overlay for visibility
    return Colors.black.withOpacity(0.3);
  }
}

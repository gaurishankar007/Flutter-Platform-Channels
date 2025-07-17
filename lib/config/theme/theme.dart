import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/ui_helpers.dart';

part 'theme_data.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: colorScheme,
  fontFamily: "Poppins",
  scaffoldBackgroundColor: AppColors.white,
  inputDecorationTheme: inputDecorationTheme,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
  ),
  checkboxTheme: checkBoxThemeData,
  listTileTheme: listTileThemeData,
  switchTheme: switchThemeData,
);

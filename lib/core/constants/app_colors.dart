import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // <=============== Color Scheme ===============>
  static const primary = primary500;
  static const accent = accent500;
  static const error = red500;
  static const success = green500;

  static const white = Colors.white;
  static const black = Colors.black;
  static const gray = Color(0xFFDCDCDC);

  // Border of text field, drop down
  static const border = Color(0XFFDBE1E5);

  // Random
  static const base = Color(0xFF121212);
  static const fade = Color(0xFF5E6A75);
  static const highlight = Color(0xFF254EDB);
  static const favorite = Color(0xFFF7D323);

  // <=============== Primary ===============>
  static const primary50 = Color(0xFFF7F3FE);
  static const primary100 = Color(0xFFEFE6FD);
  static const primary200 = Color(0xFFE0CDFA);
  static const primary250 = Color(0xFFC19AF5);
  static const primary500 = Color(0xFF6302E7);
  static const primary700 = Color(0xFF4B00B2);
  static const primary900 = Color(0xFF340278);

  // <=============== Accent ===============>
  static const accent50 = Color(0xFFFEF7F1);
  static const accent100 = Color(0xFFFDEFE3);
  static const accent200 = Color(0xFFFBDFC7);
  static const accent250 = Color(0xFFF8BF8E);
  static const accent500 = Color(0xFFF1801D);
  static const accent700 = Color(0xFFDA6703);
  static const accent900 = Color(0xFFC0500A);

  // <=============== Green Semantic ===============>
  static const green50 = Color(0xFFF4FBEF);
  static const green100 = Color(0xFFE9F7E0);
  static const green200 = Color(0xFFD3EFC1);
  static const green250 = Color(0xFFA6E082);
  static const green500 = Color(0xFF4DC105);
  static const green700 = Color(0xFF4AA910);
  static const green900 = Color(0xFF3F8612);

  // <=============== Red Semantic ===============>
  static const red50 = Color(0xFFFDF1F1);
  static const red100 = Color(0xFFFBE3E4);
  static const red200 = Color(0xFFF6C7C9);
  static const red250 = Color(0xFFED8E93);
  static const red500 = Color(0xFFDA1E28);
  static const red700 = Color(0xFFB7222A);
  static const red900 = Color(0xFF9B1E17);

  // <=============== Typography (Black - on light background) ===============>
  static final black87 = Colors.black.withAlpha(222);
  static final black60 = Colors.black.withAlpha(153);
  static final black38 = Colors.black.withAlpha(97);

  // <=============== Typography (White - on dark background) ===============>
  // 87% opacity = 221.85 alpha
  static final white87 = Colors.white.withAlpha(222);
  static final white60 = Colors.white.withAlpha(153);
  static final white38 = Colors.white.withAlpha(97);

  // <=============== Gradient ===============>
  static final gradientLTR = LinearGradient(colors: [accent500, primary500]);
  static final gradientLightTTB = LinearGradient(
    colors: [AppColors.accent100, AppColors.primary100],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static final gradientGlassmorphismLTR = LinearGradient(
    colors: [AppColors.white.withAlpha(127), AppColors.white.withAlpha(51)],
  );
  static final gradientGlassmorphismTTB = LinearGradient(
    colors: [AppColors.white.withAlpha(127), AppColors.white.withAlpha(51)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // <=============== Box Shadow ===============>
  static final blackBoxShadow = [
    BoxShadow(
      color: AppColors.black.withAlpha(25),
      offset: Offset(0, 20),
      blurRadius: 40,
    ),
  ];
}

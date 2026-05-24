import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core
  static const Color red        = Color(0xFFFF1A1A);
  static const Color redDim     = Color(0xFF8B0000);
  static const Color orange     = Color(0xFFFF6B00);
  static const Color yellow     = Color(0xFFFFD600);
  static const Color green      = Color(0xFF00FF88);
  static const Color greenDim   = Color(0xFF00AA55);

  // Backgrounds
  static const Color bg         = Color(0xFF0A0A0A);
  static const Color surface    = Color(0xFF111111);
  static const Color surface2   = Color(0xFF1A1A1A);
  static const Color border     = Color(0xFF2A2A2A);

  // Text
  static const Color textPrimary  = Color(0xFFE8E8E8);
  static const Color textDim      = Color(0xFF666666);

  // Semantic
  static const Color sosIdle      = redDim;
  static const Color sosCounting  = orange;
  static const Color sosActive    = red;
  static const Color statusOk     = green;
  static const Color statusWarn   = yellow;
  static const Color statusError  = red;
}

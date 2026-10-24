import 'package:flutter/painting.dart';

/// Central color tokens. Widgets must not hardcode colors outside this file.
abstract final class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF9FAFB);
  static const simulator = Color(0xFFF3F4F6);
  static const border = Color(0xFFE5E7EB);
  static const text = Color(0xFF111111);
  static const heading = Color(0xFF000000);
  static const muted = Color(0xFF6B7280);
  static const icon = Color(0xFF9CA3AF);

  static const success = Color(0xFF059669);
  static const successSurface = Color(0xFFECFDF5);
  static const alert = Color(0xFFDC2626);
  static const alertSurface = Color(0xFFFEF2F2);
  static const focus = Color(0xFF2563EB);

  static const deviceBackground = Color(0xFF000000);
  static const deviceText = Color(0xFFFFFFFF);
  static const deviceMuted = Color(0xB3FFFFFF);
  static const deviceButton = Color(0xFF059669);

  static const alertBorder = Color(0x33DC2626);
  static const successBorder = Color(0x33059669);
}

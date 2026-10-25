import 'package:flutter/painting.dart';

/// Central color tokens. Widgets must not hardcode colors outside this file.
///
/// One brand accent (deep teal) on a refined zinc neutral scale. Success and
/// alert stay semantically distinct from the brand color.
abstract final class AppColors {
  // Brand accent.
  static const primary = Color(0xFF0F766E);
  static const primaryHover = Color(0xFF115E59);
  static const primaryPressed = Color(0xFF134E4A);
  static const primarySurface = Color(0xFFF0FDFA);
  static const primaryBorder = Color(0x330F766E);
  static const onPrimary = Color(0xFFFFFFFF);

  /// Brand accent tuned for near-black device surfaces.
  static const primaryOnDark = Color(0xFF2DD4BF);

  // Zinc neutrals.
  static const background = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFFAFAFA);
  static const simulator = Color(0xFFF4F4F5);
  static const border = Color(0xFFE4E4E7);
  static const borderStrong = Color(0xFFD4D4D8);
  static const text = Color(0xFF18181B);
  static const heading = Color(0xFF09090B);
  static const muted = Color(0xFF71717A);
  static const icon = Color(0xFFA1A1AA);

  // Interaction overlays (flat, no shadows).
  static const overlayHover = Color(0x0A18181B);
  static const overlayPressed = Color(0x1418181B);

  /// Keyboard focus ring: 5.5:1 against white surfaces.
  static const focus = primary;

  /// Focus ring around filled brand surfaces, where [focus] would vanish.
  static const focusOnPrimary = Color(0xFF042F2E);

  // Semantic states.
  static const success = Color(0xFF059669);
  static const successSurface = Color(0xFFECFDF5);
  static const alert = Color(0xFFDC2626);
  static const alertSurface = Color(0xFFFEF2F2);
  static const alertBorder = Color(0x33DC2626);
  static const successBorder = Color(0x33059669);

  // Device (resident) mode.
  static const deviceBackground = Color(0xFF0A0A0A);
  static const deviceText = Color(0xFFFFFFFF);
  static const deviceMuted = Color(0xB3FFFFFF);
  static const deviceSubtle = Color(0x40FFFFFF);
  static const deviceButton = success;
  static const deviceOverlayHover = Color(0x14FFFFFF);
  static const deviceOverlayFocus = Color(0x1FFFFFFF);
}

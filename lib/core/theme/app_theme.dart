import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Type scale. Styles inherit the font family from [AppTheme.light].
abstract final class AppTextStyles {
  static const fontFamily = 'Inter';
  static const fontFamilyFallback = [
    'Roboto',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const display = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w600,
    height: 1.05,
    letterSpacing: -1.5,
    color: AppColors.heading,
  );
  static const pageTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.6,
    color: AppColors.heading,
  );
  static const section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.heading,
  );
  static const body = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.text,
  );
  static const bodyStrong = TextStyle(
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const secondary = TextStyle(
    fontSize: 13,
    height: 1.45,
    color: AppColors.muted,
  );
  static const micro = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.muted,
  );
}

abstract final class AppTheme {
  static WidgetStateProperty<BorderSide?> _focusSide(BorderSide? idle) =>
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? const BorderSide(color: AppColors.focus, width: 2)
            : idle,
      );

  static final WidgetStateProperty<Color?> _overlay =
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? const Color(0x0A000000)
            : Colors.transparent,
      );

  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
  );
  static const _buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.text,
      secondary: AppColors.success,
      onSecondary: AppColors.background,
      error: AppColors.alert,
      onSurface: AppColors.text,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      colorScheme: scheme,
      fontFamily: AppTextStyles.fontFamily,
      fontFamilyFallback: AppTextStyles.fontFamilyFallback,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.surfaceSecondary,
      focusColor: Colors.transparent,
      textTheme: const TextTheme(
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.secondary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.muted, size: 20),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
        textStyle: TextStyle(fontSize: 12, color: AppColors.background),
        decoration: BoxDecoration(
          color: AppColors.text,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        titleTextStyle: AppTextStyles.section,
        contentTextStyle: AppTextStyles.body,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.text,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: _buttonShape,
          textStyle: _buttonText,
        ).copyWith(side: _focusSide(null), overlayColor: _overlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              backgroundColor: AppColors.background,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              shape: _buttonShape,
              textStyle: _buttonText,
            ).copyWith(
              side: _focusSide(const BorderSide(color: AppColors.border)),
              overlayColor: _overlay,
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: _buttonShape,
          textStyle: _buttonText,
        ).copyWith(side: _focusSide(null), overlayColor: _overlay),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: _buttonShape,
        ).copyWith(side: _focusSide(null)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.background),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success
              : AppColors.border,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? AppColors.focus
              : Colors.transparent,
        ),
      ),
    );
  }
}

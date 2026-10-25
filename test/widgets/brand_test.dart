import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/core/constants/app_strings.dart';
import 'package:sessiz_komsu/core/theme/app_colors.dart';
import 'package:sessiz_komsu/core/theme/app_theme.dart';
import 'package:sessiz_komsu/core/widgets/logo_mark.dart';
import 'package:sessiz_komsu/models/app_mode.dart';
import 'package:sessiz_komsu/providers/app_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

Future<void> _pumpFamily(WidgetTester tester, Size size) async {
  SharedPreferences.setMockInitialValues({
    AppModeProvider.modeKey: AppMode.family.name,
  });
  final prefs = await SharedPreferences.getInstance();
  await pumpSessizKomsu(tester, preferences: prefs, size: size);
}

void main() {
  testWidgets('logo mark paints at favicon size with an accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: LogoMark(size: 16)),
      ),
    );
    expect(tester.getSize(find.byType(LogoMark)), const Size(16, 16));
    expect(find.bySemanticsLabel('${AppStrings.appName} logosu'), findsOne);
  });

  test('logo painter repaints only when its colors change', () {
    const base = LogoMarkPainter(
      color: AppColors.heading,
      accent: AppColors.primary,
    );
    expect(
      base.shouldRepaint(
        const LogoMarkPainter(
          color: AppColors.heading,
          accent: AppColors.primary,
        ),
      ),
      isFalse,
    );
    expect(
      base.shouldRepaint(
        const LogoMarkPainter(
          color: AppColors.heading,
          accent: AppColors.primary,
          tile: true,
        ),
      ),
      isTrue,
    );
  });

  test('theme uses the single teal brand accent', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(AppColors.primary, const Color(0xFF0F766E));
    expect(AppColors.success, isNot(AppColors.primary));
    expect(AppColors.alert, isNot(AppColors.primary));

    final filled = theme.filledButtonTheme.style!;
    expect(filled.backgroundColor!.resolve({}), AppColors.primary);
    expect(
      filled.backgroundColor!.resolve({WidgetState.hovered}),
      AppColors.primaryHover,
    );
    expect(
      filled.side!.resolve({WidgetState.focused})!.color,
      AppColors.focusOnPrimary,
    );
    expect(filled.elevation!.resolve({}), 0);
  });

  testWidgets('onboarding and desktop sidebar show the brand mark', (
    tester,
  ) async {
    await pumpSessizKomsu(tester);
    expect(find.byType(LogoMark), findsOne);

    await _pumpFamily(tester, const Size(1440, 900));
    expect(find.byType(LogoMark), findsOne);
    expect(find.byType(LogoLockup), findsNothing);
  });

  testWidgets('phones show the wordmark lockup instead of a sidebar', (
    tester,
  ) async {
    await _pumpFamily(tester, const Size(390, 844));
    expect(find.byType(LogoLockup), findsOne);
    expect(find.bySemanticsLabel(AppStrings.appName), findsOne);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sessiz_komsu/core/constants/app_strings.dart';

import '../helpers/test_app.dart';

/// End-to-end demo flow on a frozen clock:
/// open → family → kitchen → alert → device → İYİYİM → confirmation in the
/// timeline → reset → normal.
void main() {
  testWidgets('complete demo flow', (tester) async {
    const kitchenEvent = 'Mutfak sensörü tetiklendi.';
    const confirmationEvent = 'Ayşe Hanım iyi olduğunu bildirdi.';

    // Open the app.
    await pumpSessizKomsu(tester);
    expect(find.text(AppStrings.modeQuestion), findsOneWidget);

    // Family dashboard, normal state with seed data.
    await tapAndSettle(tester, find.text(AppStrings.familyModeTitle));
    expect(find.text(AppStrings.homeName), findsOneWidget);
    expect(find.text(AppStrings.bannerNormal), findsOneWidget);
    expect(find.text(kitchenEvent), findsNWidgets(2));

    // Kitchen sensor.
    await tapAndSettle(tester, find.text('Mutfak Prizini Aç'));
    expect(find.text(kitchenEvent), findsNWidgets(3));
    expect(find.text(AppStrings.bannerNormal), findsOneWidget);

    // Alert scenario: one click raises the alert everywhere.
    await tapAndSettle(tester, find.text('Uyarı Senaryosunu Başlat'));
    expect(find.text(AppStrings.bannerDelayed), findsOneWidget);
    expect(find.text('Uyarı senaryosu başlatıldı.'), findsOneWidget);
    expect(find.text('Sabah rutini gecikti.'), findsOneWidget);
    expect(find.text('25 Ekim 2026, Pazar · 10:30'), findsOneWidget);

    // Device mode shows İYİYİM.
    await tapAndSettle(tester, find.byTooltip('Cihaz Modu'));
    expect(find.text(AppStrings.confirmButton), findsOneWidget);

    await tester.tap(find.text(AppStrings.confirmButton));
    await settle(tester);
    expect(find.text(AppStrings.confirmButton), findsNothing);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text(AppStrings.confirmThanks), findsOneWidget);

    // Back to the family dashboard: confirmation is visible.
    await tapAndSettle(tester, find.byTooltip(AppStrings.backToModeSelection));
    await tapAndSettle(tester, find.text(AppStrings.familyModeTitle));
    expect(find.text(AppStrings.bannerConfirmed), findsOneWidget);
    expect(find.text(confirmationEvent), findsOneWidget);

    // Reset everything.
    await tapAndSettle(tester, find.text(AppStrings.resetDemo));
    await tapAndSettle(tester, find.text('Sıfırla'));
    expect(find.text(AppStrings.bannerNormal), findsOneWidget);
    expect(find.text(confirmationEvent), findsNothing);
    expect(find.text(kitchenEvent), findsNWidgets(2));
    expect(find.text('24 Ekim 2026, Cumartesi · 08:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

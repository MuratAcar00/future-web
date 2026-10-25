# Codex Handoff — Sessiz Komşu (Flutter Web)

**Date:** 2026-10-25
**Repo:** https://github.com/MuratAcar00/future-web (default branch `main`)
**Local path:** `C:\Users\Piro\Desktop\future-web` (clean, at `origin/main`)
**Current `main`:** `f859501` (Merge PR #3)
**Toolchain:** Flutter 3.47.5 stable (Dart bundled)

---

## 1. What this is

Ideathon prototype of **Sessiz Komşu**: an elderly daily-routine support system with no camera, microphone or wearable. **Every sensor is simulated.** There is no backend, no real hardware, no real notifications. The UI must stay honest about that: label demo data as simulated, and never claim a real connection.

Two modes, chosen at onboarding:
- **Device Mode:** black screen for the elderly user with a huge clock and Turkish date. When a routine alert fires, a full-screen pulsing green **"İYİYİM"** confirmation button replaces the clock.
- **Family Mode:** desktop-first web dashboard in three columns:
  - left: sidebar (Ev / Ayarlar / Profil)
  - center: header, routine banner, sensor status overview, AnimatedList timeline
  - right: "Geliştirici / Demo Kontrolleri" simulator panel

Both modes share the same in-memory provider state in one browser tab.

## 2. Merged history

| PR | Content | Review |
|---|---|---|
| #1 | Full app: providers, onboarding, device, family dashboard, demo panel, tests, README | not reviewed |
| #2 | Modern logo (`LogoMark`, CustomPainter house + dot), favicon and web icons, deep-teal theme (`#0F766E`), zinc neutrals, Inter font | not reviewed |
| #3 | **Sunum Modu**: 7-step guided auto-play presentation driving the real providers | not reviewed |

All three PRs were merged **without code review**. The AO reviewer hung each time and the user approved merging anyway. Worker-reported results at PR #3: `flutter analyze` clean, **71/71 tests pass**, `flutter build web --release` OK.

## 3. Architecture

- **State management:** `provider` only. Dependencies: `provider`, `intl`, `shared_preferences` (stores only the chosen mode).
- **Data flow:**
  1. `DemoSensorService` creates the `SensorEvent`s (seed history plus button-triggered events).
  2. `SensorProvider` stores them in a newest-first list and dedupes by deterministic id `type-yyyyMMddHHmm`.
  3. `RoutineEngine` decides the routine status. It is pure and deterministic.
  4. `RoutineProvider` re-runs the engine on every event and every clock change.
  5. The UI reads the providers.
- **Clock:** `ClockProvider` keeps real time and demo time separate (demo offset). It runs a single periodic timer and accepts an injectable clock for tests.
- **Routine rules** (`lib/services/routine_engine.dart`):
  - confirmation today → `confirmedOkay`
  - any activity since 05:00 → `normal`
  - before 09:00 → `normal`
  - 09:00–09:30 → `delayed`
  - after 09:30 → `awaitingConfirmation` (Device Mode shows İYİYİM)
- **Coordinators:**
  - `DemoProvider` runs the scenarios: +1h, alert scenario, reset.
  - `PresentationProvider` plus the `PresentationStep` model run the guided tour: one timer, pause/resume, prev/next, Esc to finish, then a clean reset.
- **Design tokens:** all in `lib/core/theme/` (`AppColors`, `AppSpacing`, `AppTheme`). No shadows, no gradients. Respect `MediaQuery.disableAnimations` (`lib/core/utils/motion.dart`).

### File map
```
lib/
  main.dart, app.dart
  core/constants/   app_constants.dart, app_strings.dart
  core/theme/       app_colors.dart, app_spacing.dart, app_theme.dart
  core/utils/       date_time_format.dart, motion.dart
  core/widgets/     hover_surface, logo_mark, reset_demo_dialog, status_dot, tag_chip
  models/           app_mode, presentation_step, routine_status, sensor, sensor_event, sensor_type
  providers/        app_mode, clock, demo, presentation, routine, sensor
  services/         demo_sensor_service.dart, routine_engine.dart
  screens/onboarding/onboarding_screen.dart
  screens/device/device_screen.dart
  screens/family/   family_dashboard.dart, profile/, settings/, widgets/
                    (activity_timeline, demo_panel, event_empty_state, family_header,
                     family_page, family_sidebar, routine_banner,
                     sensor_status_overview, timeline_item)
  screens/presentation/ presentation_highlight.dart, presentation_layer.dart
test/
  helpers/test_app.dart
  integration/app_flow_test.dart
  providers/  (app_mode, clock, demo, presentation, routine, sensor)
  widgets/    (brand, device_screen, family_dashboard, onboarding_screen, presentation)
```

## 4. Commands
```
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
flutter build web --release      # output: build/web
```

## 5. Open / unfinished work

### A. Add Device ("Cihaz Ekleme"): CANCELLED, not in `main`
The user started this feature, then cancelled it before any PR was opened. Nothing was pushed. Partial local work may remain in the AO worktree of killed session `future-web-5` (branch `ao/add-device/root`, unpushed). Treat that work as unreliable. Full spec: `cihaz-ekle-brief.md` (same folder as this file). Summary:
- A "Cihaz Ekle" entry in the family dashboard and in Settings > Cihazlar, offering 3 simulated methods:
  1. **QR Kod ile Cihaz Ekle**, local Wi-Fi/Bluetooth devices. **No camera access.** Simulated scan, or manual code `SK-XXXX-XXXX`, then room, then name.
  2. **Cihazları Tara**, Zigbee sensors and smart TVs. Simulated discovery list, then select, then assign a room.
  3. **Hesap Bağla**, cloud integrations: Google Home, Alexa, Bosch Smart Home, SmartThings. Simulated consent screen, link/unlink, imported devices. Use text labels only, no trademark logos.
- New `DeviceProvider` plus models and a simulated pairing service. Added devices appear in the sensor overview and create timeline events. "Demo'yu Sıfırla" and finishing Sunum Modu must reset them.
- Start only if the user asks again.

### B. Not verified
- No human or AO code review on any PR.
- Desktop width for Sunum Modu was covered only by widget tests. Phone width for the logo/theme was covered only by widget tests.
- AO's native reviewer hung on PRs #1–#3. Don't rely on it.

## 6. Hard rules (from the original brief)
- Desktop-first Flutter Web. Keep the minimal, shadow-free Linear/Vercel-style look, which the user likes.
- Logic belongs in providers and services, not in widgets. No giant files. No dead buttons, no TODOs.
- Be honest about the simulation: no fake backend or sensor claims, no health diagnoses. Use "Sabah rutini gecikti. Lütfen kontrol edin."
- Privacy: no camera, microphone or location permissions.
- Before claiming done, run analyze, test and build and report the real exit codes.
- Publishing: push or open a PR only when the user asks. The user previously authorized PRs to `main` for features they requested.

## 7. Related docs (same folder as this file)
- `sessiz-komsu-spec.md`: original full product spec (condensed)
- `logo-tema-brief.md`: logo/theme brief (PR #2)
- `sunum-modu-brief.md`: presentation mode brief (PR #3)
- `cihaz-ekle-brief.md`: cancelled Add Device brief
- `sessiz-komsu-mimari.pdf`: real-world architecture proposal (sensors → hub → server), user-facing, in Turkish

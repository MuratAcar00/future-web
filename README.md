# Sessiz Komşu

Sessiz Komşu is a Flutter Web demo that follows an elderly person's daily
routine through **simulated** home sensors (kitchen plug, entrance door,
bedroom motion) while protecting their privacy. A family member sees the
routine on a web dashboard; the resident sees a calm clock and confirms with a
single large **İYİYİM** button when the morning routine is late.

> **This is a demo.** There are no real sensors, no backend, and no push
> notifications or SMS. All data is generated in the browser and labelled
> "simüle" in the UI. The app makes no health assessments; it only reports
> routine timing (e.g. "Sabah rutini gecikti. Lütfen kontrol edin.").

## Stack

- Flutter 3.47.5 (stable) / Dart 3.13.4, web target
- State management: [`provider`](https://pub.dev/packages/provider)
  (`ChangeNotifier`, `context.select`)
- `intl` for time formatting, `shared_preferences` to remember **only** the
  selected mode
- No other runtime dependencies

## Architecture

```
UI (screens/, core/widgets/)
   │  context.select / context.read
   ▼
Providers (providers/)                    Services (services/)
 AppModeProvider  mode, nav, UI prefs      RoutineEngine      pure routine rules
 ClockProvider    real vs demo time        DemoSensorService  simulated events + copy
 SensorProvider   sensors + event log
 RoutineProvider  status from engine  ─────────▶ RoutineEngine
 DemoProvider     demo scenarios      ─────────▶ DemoSensorService
   │
   ▼
Models (models/)  AppMode, SensorType, Sensor, SensorEvent, RoutineStatus
```

- **ClockProvider** keeps real time and the demo offset apart (`realNow`,
  `currentTime`, `demoOffset`, `isDemoTimeActive`). It runs one
  `Timer.periodic`, notifies once per minute, and cancels the timer on
  dispose. The clock function can be injected, so tests are deterministic.
- **SensorProvider** stores events newest-first with a stable tie-breaker and
  drops duplicates by id. Event ids are deterministic, so repeating an action
  never adds the same event twice.
- **RoutineProvider** listens to the clock and to the sensors and asks
  `RoutineEngine` for the status. Widgets never decide the status. `batch()`
  groups several changes into a single evaluation.
- **DemoProvider** runs the demo panel actions. Each one is idempotent, and
  reset restores clock, sensors, routine and demo state.

### Routine rules (`RoutineEngine`)

Every rule applies to the day of the current (demo) time:

| Condition | Status |
|---|---|
| İYİYİM pressed that day | `confirmedOkay` |
| Sensor activity since 05:00 | `normal` ("Ayşe Hanım güne başladı…") |
| No activity, before 09:00 | `normal`, still waiting |
| No activity, 09:00–09:30 | `delayed`, red banner for the family |
| No activity, from 09:30 | `awaitingConfirmation`, red banner + İYİYİM on the device |

## Project structure

```
lib/
  main.dart, app.dart            bootstrap, MultiProvider, mode switcher
  core/constants/                durations, breakpoints, layout, shared copy
  core/theme/                    AppColors, AppSpacing/AppRadius, AppTheme
  core/utils/                    Turkish date formatting, reduced-motion helper
  core/widgets/                  HoverSurface, LogoMark, StatusDot, TagChip, reset dialog
  models/                        app_mode, sensor_type, sensor, sensor_event, routine_status
  providers/                     app_mode, clock, sensor, routine, demo
  services/                      routine_engine, demo_sensor_service
  screens/onboarding/            mode selection
  screens/device/                black clock screen + İYİYİM prompt
  screens/family/                dashboard shell
    widgets/                     sidebar/bottom nav, header, banner, sensors,
                                 timeline (AnimatedList), timeline item, empty state, demo panel
    settings/, profile/          settings and profile sections
test/
  providers/                     clock, sensor, routine (+engine), demo, app mode
  widgets/                       onboarding, device, family dashboard (5 widths)
  integration/                   end-to-end demo flow
  helpers/                       frozen clock and pump helpers
```

## Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome          # development
flutter build web --release    # output: build/web
```

`build/web` is a static bundle. Serve it from its own root, e.g.
`python -m http.server 8080 --directory build/web`, or rebuild with
`--base-href /sub/path/` to host it under a sub-path.

## Using the demo

1. On first launch choose **Yakınım İçin — Aile Paneli** (family dashboard) or
   **Benim İçin — Cihaz Modu** (device screen). The choice survives a page
   refresh. The demo data does not.
2. The dashboard opens with seed events (07:12 bedroom, 07:30 kitchen, and
   the previous evening's 21:45 / 22:18). Before 07:30 the morning seeds move
   to the previous day so they are never in the future.
3. In **Geliştirici / Demo Kontrolleri**:
   - **Mutfak Prizini Aç / Dış Kapı Sensörü / Yatak Odası Hareketi** add a
     simulated sensor event. A repeat within the same minute is ignored.
   - **Zamanı Hızlandır (+1 Saat)** moves demo time forward and re-evaluates
     the routine.
   - **Uyarı Senaryosunu Başlat** jumps to the next quiet late morning (10:30)
     and raises the alert in one click: red banner, timeline events, and
     İYİYİM on the device screen. It is disabled while an alert is active.
   - **Demo'yu Sıfırla** asks for confirmation, then resets all providers.
4. Open device mode (sidebar tablet icon) and press **İYİYİM**, by click,
   touch, Enter or Space. The confirmation shows up in the family timeline
   and the banner reads "Ayşe Hanım iyi olduğunu doğruladı."

## Accessibility & motion

- Visible blue focus ring, keyboard activation, tooltips and semantic labels
  on every interactive element. Status is never shown by color alone: there
  are always labels and tags as well.
- Reduced motion: the OS setting (`MediaQuery.disableAnimations`) or
  **Ayarlar → Hareketi azalt** turns off transitions and the İYİYİM pulse.
- Layouts are verified at 1440, 1280, 1024, 768 and 390 px widths with no
  overflow (widget tests).

## Limitations / not included

- No real sensor hardware, no backend or database, no authentication.
- No push notifications, SMS or calls. Alerts exist only inside this app.
- Demo state lives in memory; only the selected mode is persisted.
- One resident and one home; the routine thresholds are fixed in code.
- The Inter font is not bundled. The theme asks for Inter and falls back to
  Roboto, which Flutter Web loads by default.
- The UI is Turkish only; no localization framework is used.

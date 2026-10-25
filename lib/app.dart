import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/motion.dart';
import 'models/app_mode.dart';
import 'providers/app_mode_provider.dart';
import 'providers/clock_provider.dart';
import 'providers/demo_provider.dart';
import 'providers/device_provider.dart';
import 'providers/presentation_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/sensor_provider.dart';
import 'screens/device/device_screen.dart';
import 'screens/family/family_dashboard.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/presentation/presentation_layer.dart';

class SessizKomsuApp extends StatelessWidget {
  const SessizKomsuApp({
    super.key,
    this.preferences,
    this.now,
    this.autoTick = true,
  });

  /// Persists the selected mode; null disables persistence.
  final SharedPreferences? preferences;

  /// Injectable clock for deterministic tests.
  final NowProvider? now;

  /// Disable the periodic clock timer in tests.
  final bool autoTick;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => AppModeProvider(preferences: preferences),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => ClockProvider(now: now, autoTick: autoTick),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => SensorProvider(
            initialTime: context.read<ClockProvider>().currentTime,
          ),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => DeviceProvider(
            sensors: context.read<SensorProvider>(),
            now: () => context.read<ClockProvider>().currentTime,
          ),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => RoutineProvider(
            clock: context.read<ClockProvider>(),
            sensors: context.read<SensorProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) => DemoProvider(
            clock: context.read<ClockProvider>(),
            sensors: context.read<SensorProvider>(),
            routine: context.read<RoutineProvider>(),
            devices: context.read<DeviceProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PresentationProvider(
            appMode: context.read<AppModeProvider>(),
            clock: context.read<ClockProvider>(),
            demo: context.read<DemoProvider>(),
            routine: context.read<RoutineProvider>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => PresentationLayer(child: child!),
        home: const _ModeSwitcher(),
      ),
    );
  }
}

/// Cross-fades between onboarding, device and family screens.
class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher();

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppModeProvider, AppMode>((p) => p.mode);
    return AnimatedSwitcher(
      duration: context.motion(AppDurations.fade),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(mode),
        child: switch (mode) {
          AppMode.onboarding => const OnboardingScreen(),
          AppMode.device => const DeviceScreen(),
          AppMode.family => const FamilyDashboard(),
        },
      ),
    );
  }
}

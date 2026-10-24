import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/app_mode_provider.dart';

extension MotionContext on BuildContext {
  /// True when the OS requests reduced motion or the in-app setting is on.
  /// Only call from `build` (it subscribes to changes).
  bool get reduceMotion =>
      MediaQuery.disableAnimationsOf(this) ||
      select<AppModeProvider, bool>((p) => p.reduceMotion);

  /// [duration], or zero when reduced motion is requested.
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}

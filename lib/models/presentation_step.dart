import 'package:flutter/foundation.dart';

import 'sensor_type.dart';

/// Screen areas the presentation can highlight.
enum PresentationTarget { banner, sensors, timeline, demoPanel }

/// Operations a presentation step may perform. Implemented by
/// `PresentationProvider` on top of the real app providers, so the story
/// drives the same state the demo panel does.
abstract interface class PresentationScript {
  void showFamily();
  void showDevice();

  /// Sets demo time to [hour]:[minute] on the story day + [dayOffset].
  void setTime(int dayOffset, int hour, int minute);
  void triggerSensor(SensorType type);
  void startAlertScenario();
  void confirmOkay();
}

/// One timed action inside a step. [at] is measured from the step start.
@immutable
class PresentationBeat {
  const PresentationBeat(this.at, this.run);

  final Duration at;
  final void Function(PresentationScript script) run;
}

/// One captioned step of the guided walkthrough.
@immutable
class PresentationStep {
  const PresentationStep({
    required this.title,
    required this.description,
    this.focus = const {},
    this.duration = const Duration(seconds: 6),
    this.beats = const [],
  });

  final String title;
  final String description;

  /// Highlighted areas; everything else is dimmed. Empty = no highlight.
  final Set<PresentationTarget> focus;

  /// Time before auto-advancing to the next step.
  final Duration duration;

  /// Actions in ascending [PresentationBeat.at] order.
  final List<PresentationBeat> beats;
}

const _beat = Duration(milliseconds: 1400);

/// The jury walkthrough: one simulated day that starts normally, followed by
/// a morning without activity, the alert, and the İYİYİM confirmation.
final presentationSteps = <PresentationStep>[
  PresentationStep(
    title: 'Sessiz Komşu nedir?',
    description:
        'Yalnız yaşayan yakınlarınızın günlük rutinini kamera ya da mikrofon '
        'olmadan, basit ev sensörleriyle sessizce takip eden bir sistem.',
    beats: [
      PresentationBeat(Duration.zero, (s) {
        s.showFamily();
        s.setTime(0, 6, 50);
      }),
    ],
  ),
  PresentationStep(
    title: 'Aile paneli',
    description:
        'Durum kartı, sensörler ve etkinlik akışı tek ekranda. Yakınınızın '
        'gününün nasıl başladığını bir bakışta görürsünüz.',
    focus: const {
      PresentationTarget.banner,
      PresentationTarget.sensors,
      PresentationTarget.timeline,
    },
    beats: [PresentationBeat(Duration.zero, (s) => s.showFamily())],
  ),
  PresentationStep(
    title: 'Sabah rutini başlıyor',
    description:
        'Mutfak prizi, buzdolabı kapağı, salon ışığı ve dış kapı gibi sınırlı '
        'sinyaller zaman çizelgesine düşer. Yatak odası hareketi izlenmez.',
    focus: const {PresentationTarget.sensors, PresentationTarget.timeline},
    duration: const Duration(seconds: 8),
    beats: [
      PresentationBeat(Duration.zero, (s) => s.showFamily()),
      PresentationBeat(_beat, (s) {
        s.setTime(0, 7, 5);
      }),
      PresentationBeat(_beat * 2, (s) {
        s.setTime(0, 7, 24);
        s.triggerSensor(SensorType.kitchen);
      }),
      PresentationBeat(_beat * 3, (s) {
        s.setTime(0, 7, 41);
        s.triggerSensor(SensorType.fridge);
      }),
      PresentationBeat(_beat * 4, (s) {
        s.setTime(0, 7, 52);
        s.triggerSensor(SensorType.entrance);
      }),
      PresentationBeat(_beat * 5, (s) {
        s.setTime(0, 7, 58);
        s.triggerSensor(SensorType.livingRoomLight);
      }),
    ],
  ),
  PresentationStep(
    title: 'Rutin gecikirse',
    description:
        'Ertesi sabah aktivite olayı kaydedilmez. 09:00’dan sonra rutin gecikmiş '
        'sayılır; 09:30’dan sonra aile paneli kırmızı uyarı verir.',
    focus: const {PresentationTarget.banner},
    duration: const Duration(seconds: 7),
    beats: [
      PresentationBeat(Duration.zero, (s) {
        s.showFamily();
        s.setTime(1, 8, 40);
      }),
      // The real demo scenario: jumps to late morning without activity.
      PresentationBeat(_beat * 2, (s) => s.startAlertScenario()),
    ],
  ),
  PresentationStep(
    title: 'Cihazda İYİYİM onayı',
    description:
        'Yaşam alanındaki ekran büyük bir İYİYİM butonu gösterir. '
        'Tek dokunuş yeterli; uygulama veya giyilebilir cihaz gerekmez.',
    beats: [PresentationBeat(Duration.zero, (s) => s.showDevice())],
  ),
  PresentationStep(
    title: 'Onay alındı',
    description:
        'İYİYİM’e basıldı: uyarı kapanır, onay etkinlik akışına düşer ve '
        'durum kartı yeşile döner.',
    focus: const {PresentationTarget.banner, PresentationTarget.timeline},
    duration: const Duration(seconds: 7),
    beats: [
      PresentationBeat(Duration.zero, (s) {
        s.showDevice();
        s.confirmOkay();
      }),
      PresentationBeat(_beat * 2, (s) => s.showFamily()),
    ],
  ),
  PresentationStep(
    title: 'Gizlilik önce gelir',
    description:
        'Kamera, mikrofon veya giyilebilir cihaz yok. Bu sunumdaki tüm '
        'veriler tarayıcıda simüle edilmiştir.',
    beats: [PresentationBeat(Duration.zero, (s) => s.showFamily())],
  ),
];

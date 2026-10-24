/// The three simulated sensors installed in the demo home.
enum SensorType {
  kitchen(
    id: 'kitchen-plug',
    name: 'Mutfak Prizi',
    location: 'Mutfak',
    triggeredState: 'Priz açıldı',
  ),
  entrance(
    id: 'entrance-door',
    name: 'Dış Kapı Sensörü',
    location: 'Giriş',
    triggeredState: 'Kapı açıldı',
  ),
  bedroom(
    id: 'bedroom-motion',
    name: 'Yatak Odası Hareket Sensörü',
    location: 'Yatak odası',
    triggeredState: 'Hareket algılandı',
  );

  const SensorType({
    required this.id,
    required this.name,
    required this.location,
    required this.triggeredState,
  });

  final String id;
  final String name;
  final String location;

  /// State text shown after the sensor last fired.
  final String triggeredState;
}

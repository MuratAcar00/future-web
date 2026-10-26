/// Privacy-conscious simulated signals used by the demo.
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
  fridge(
    id: 'fridge-door',
    name: 'Buzdolabı Kapı Sensörü',
    location: 'Mutfak',
    triggeredState: 'Kapak açıldı',
  ),
  livingRoomLight(
    id: 'living-room-light',
    name: 'Salon Işığı',
    location: 'Salon',
    triggeredState: 'Işık açıldı',
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

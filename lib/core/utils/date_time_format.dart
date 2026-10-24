import 'package:intl/intl.dart';

/// Turkish date/time formatting that does not depend on async locale loading.
///
/// Month and weekday names are kept here so formatting works identically in
/// the browser and in tests, without `initializeDateFormatting`.
abstract final class TurkishDateFormat {
  static const _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  static const _weekdays = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  static final _time = DateFormat('HH:mm');
  static final _stamp = DateFormat('yyyyMMddHHmm');
  static final _dayStamp = DateFormat('yyyyMMdd');

  /// `07:30`
  static String time(DateTime value) => _time.format(value);

  /// `24 Ekim 2026, Cumartesi`
  static String longDate(DateTime value) =>
      '${value.day} ${_months[value.month - 1]} ${value.year}, '
      '${_weekdays[value.weekday - 1]}';

  /// `24 Ekim`
  static String shortDate(DateTime value) =>
      '${value.day} ${_months[value.month - 1]}';

  /// `Bugün`, `Dün`, `Yarın` or `24 Ekim`, relative to [now].
  static String relativeDay(DateTime value, DateTime now) {
    final diff = value.startOfDay.difference(now.startOfDay).inDays;
    return switch (diff) {
      0 => 'Bugün',
      -1 => 'Dün',
      1 => 'Yarın',
      _ => shortDate(value),
    };
  }

  /// `Bugün 07:30`, `Dün 22:18`.
  static String relative(DateTime value, DateTime now) =>
      '${relativeDay(value, now)} ${time(value)}';

  /// `09:30` for a duration measured from midnight.
  static String timeOfDay(Duration sinceMidnight) {
    final hours = sinceMidnight.inHours.toString().padLeft(2, '0');
    final minutes = (sinceMidnight.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Minute-precision key used for deterministic event ids.
  static String stamp(DateTime value) => _stamp.format(value);

  /// Day-precision key used for once-per-day event ids.
  static String dayStamp(DateTime value) => _dayStamp.format(value);
}

extension DateTimeDayX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// The same calendar day at [sinceMidnight].
  DateTime atTimeOfDay(Duration sinceMidnight) => startOfDay.add(sinceMidnight);
}

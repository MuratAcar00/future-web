import 'package:flutter/foundation.dart';

/// Cloud smart-home platforms offered by the "Hesap Bağla" flow.
///
/// Text labels only: the app never ships third-party logos and never
/// contacts these services.
enum CloudProvider {
  googleHome('Google Home'),
  amazonAlexa('Amazon Alexa'),
  boschSmartHome('Bosch Smart Home'),
  smartThings('SmartThings');

  const CloudProvider(this.label);

  final String label;
}

/// A (simulated) linked cloud account and the devices imported from it.
@immutable
class CloudAccount {
  const CloudAccount({
    required this.provider,
    required this.linkedAt,
    required this.deviceIds,
  });

  final CloudProvider provider;
  final DateTime linkedAt;

  /// Ids of the devices imported when the account was linked.
  final List<String> deviceIds;
}

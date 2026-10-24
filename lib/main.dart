import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } on Object {
    // Storage can be unavailable (e.g. blocked in private browsing). The app
    // still works; it just won't remember the selected mode.
    preferences = null;
  }
  runApp(SessizKomsuApp(preferences: preferences));
}

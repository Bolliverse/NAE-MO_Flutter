import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:nae_mo/app.dart';
import 'package:nae_mo/core/platform/firebase_auth_platform.dart';
import 'package:nae_mo/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}\n${details.stack}');
  };

  try {
    if (supportsFirebaseAuth) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await initializeDateFormatting('ko', null);
  } catch (e, stack) {
    debugPrint('Initialization error: $e\n$stack');
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

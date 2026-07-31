import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:nae_mo/app.dart';
import 'package:nae_mo/core/platform/firebase_auth_platform.dart';
import 'package:nae_mo/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supportsFirebaseAuth) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await initializeDateFormatting('ko', null);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

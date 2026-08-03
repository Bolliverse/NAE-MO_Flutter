import 'package:flutter/foundation.dart';

bool isFirebaseAuthPlatform(
  TargetPlatform platform, {
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

bool get supportsFirebaseAuth => isFirebaseAuthPlatform(defaultTargetPlatform);

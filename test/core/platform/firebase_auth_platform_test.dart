import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/platform/firebase_auth_platform.dart';
import 'package:nae_mo/features/auth/data/datasources/unsupported_auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

void main() {
  test('supports Firebase authentication on Android and iOS only', () {
    expect(isFirebaseAuthPlatform(TargetPlatform.android), isTrue);
    expect(isFirebaseAuthPlatform(TargetPlatform.iOS), isTrue);
    expect(isFirebaseAuthPlatform(TargetPlatform.windows), isFalse);
    expect(isFirebaseAuthPlatform(TargetPlatform.linux), isFalse);
    expect(isFirebaseAuthPlatform(TargetPlatform.macOS), isFalse);
  });

  test('does not enable the mobile Firebase flow on web', () {
    expect(
      isFirebaseAuthPlatform(TargetPlatform.android, isWeb: true),
      isFalse,
    );
  });

  test('unsupported source restores safely and explains sign-in support',
      () async {
    const source = UnsupportedAuthSessionRemoteDataSource();

    expect(await source.restoreSession(), isNull);
    await expectLater(
      () => source.signIn(AuthProviderType.google),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Google 및 Apple 로그인은 Android와 iOS에서 지원됩니다.',
        ),
      ),
    );
    await source.signOut();
  });
}

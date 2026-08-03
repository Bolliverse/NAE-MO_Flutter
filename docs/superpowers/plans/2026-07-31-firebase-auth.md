# NAE MO Firebase Auth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the temporary SharedPreferences Google/Apple session with real Firebase Authentication on Android and iOS while preserving the existing login UI, router guards, and logout UX.

**Architecture:** Keep Presentation → ViewModel → UseCase → Repository unchanged. Replace the local auth data source with a Firebase remote data source backed by testable FirebaseAuth and GoogleSignIn gateways; expose only Firebase `uid` and the selected provider to Domain. Initialize Firebase only on Android/iOS and return a clear unsupported-platform result elsewhere.

**Tech Stack:** Flutter 3.24.5, Dart 3.5.4, Riverpod 2.6.1, Firebase Core/Auth, google_sign_in 7.x-compatible API, FlutterFire CLI, Firebase CLI, Android Gradle, iOS CocoaPods/Xcode project files.

---

## File map

### Create

- `lib/features/auth/data/models/remote_auth_user.dart`: Firebase-neutral remote user record.
- `lib/features/auth/data/datasources/auth_session_remote_data_source.dart`: remote auth boundary.
- `lib/features/auth/data/datasources/firebase_auth_session_remote_data_source.dart`: provider flows, cancellation, logout ordering, and SDK error normalization.
- `lib/features/auth/data/datasources/unsupported_auth_session_remote_data_source.dart`: safe behavior outside Android/iOS.
- `lib/features/auth/data/gateways/firebase_auth_gateway.dart`: thin FirebaseAuth adapter.
- `lib/features/auth/data/gateways/google_sign_in_gateway.dart`: thin google_sign_in adapter with one-time initialization.
- `lib/features/auth/data/auth_error_messages.dart`: pure Firebase/Google error-code mapping.
- `lib/core/platform/firebase_auth_platform.dart`: supported-platform predicate.
- `lib/firebase_options.dart`: generated Firebase configuration for project `naem-o`.
- `test/features/auth/data/auth_error_messages_test.dart`: error mapping tests.
- `test/features/auth/data/datasources/firebase_auth_session_remote_data_source_test.dart`: remote flow tests with fake gateways.
- `test/core/platform/firebase_auth_platform_test.dart`: platform support tests.
- `android/app/google-services.json`: registered Android Firebase app configuration.
- `android/app/src/main/kotlin/com/bolliverse/todo/todo_project/MainActivity.kt`: Android entry point with the registered package.
- `ios/Podfile`: CocoaPods config with iOS 15 minimum.
- `ios/Runner/GoogleService-Info.plist`: registered iOS Firebase app configuration.
- `ios/Runner/Runner.entitlements`: repository-side Sign in with Apple entitlement.
- `docs/FIREBASE_AUTH_SETUP.md`: Apple-owner setup and device verification handoff.

### Modify

- `.gitignore`: track the application `pubspec.lock`.
- `pubspec.yaml`, `pubspec.lock`: Firebase/Google dependencies; remove auth-only SharedPreferences dependencies.
- `lib/main.dart`: initialize Firebase on supported platforms before app startup.
- `lib/core/errors/app_exception.dart`, `lib/core/errors/failure.dart`: auth-specific error types.
- `lib/features/auth/domain/entities/auth_session.dart`: store `uid` and provider.
- `lib/features/auth/data/repositories/auth_session_repository_impl.dart`: consume remote auth instead of local provider storage.
- `lib/features/auth/auth_providers.dart`: wire gateways, remote source, and repository.
- `lib/features/auth/presentation/viewmodels/auth_view_model.dart`: auth-specific fallback messages.
- `test/features/auth/data/repositories/auth_session_repository_impl_test.dart`: remote user mapping, cancellation, and auth failures.
- `test/features/auth/presentation/viewmodels/auth_view_model_test.dart`: uid-aware sessions and auth failures.
- `test/widget_test.dart`: uid-aware fake sessions and cancellation behavior.
- `android/settings.gradle`, `android/app/build.gradle`: Google services plugin, package ID, and minimum SDK.
- `ios/Runner.xcodeproj/project.pbxproj`: bundle ID, deployment target, service plist, and entitlements.
- `ios/Runner/Info.plist`: Google client ID and reversed-client-ID URL scheme.

### Delete

- `lib/features/auth/data/datasources/auth_session_local_data_source.dart`
- `lib/features/auth/data/datasources/auth_session_local_data_source_impl.dart`
- `test/features/auth/integration/auth_persistence_integration_test.dart`
- `android/app/src/main/kotlin/com/example/nae_mo/MainActivity.kt`

## Task 1: Install tooling, resolve dependencies, and fetch Firebase configuration

**Files:**
- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Create/track: `pubspec.lock`
- Create: `lib/firebase_options.dart`
- Create: `android/app/google-services.json`
- Create: `ios/Runner/GoogleService-Info.plist`
- Create/modify: `firebase.json`

- [ ] **Step 1: Verify the Firebase account and registered apps before writing repository files**

Run:

```powershell
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
firebase projects:list
firebase apps:list --project naem-o
```

Expected: project `naem-o` is visible; one Android app has package `com.bolliverse.todo.todo_project`; one iOS app has bundle ID `com.bolliverse.todo.todoProject`.

- [ ] **Step 2: Replace auth-only local-storage dependencies and add Firebase dependencies**

Run:

```powershell
flutter pub remove shared_preferences shared_preferences_platform_interface
flutter pub add firebase_core firebase_auth google_sign_in
```

Expected: the resolver selects versions compatible with Flutter 3.24.5/Dart 3.5.4 and updates `pubspec.yaml` plus `pubspec.lock`.

- [ ] **Step 3: Make the application lockfile trackable**

Append this exact exception after `*.lock` handling in `.gitignore`:

```gitignore
# Flutter application dependencies must be reproducible.
!pubspec.lock
```

Run `git check-ignore -v pubspec.lock`; expected: exit code 1, meaning the file is no longer ignored.

- [ ] **Step 4: Generate Android/iOS Firebase options using the registered app identifiers**

Run:

```powershell
flutterfire configure --yes --project=naem-o --platforms=android,ios --android-package-name=com.bolliverse.todo.todo_project --ios-bundle-id=com.bolliverse.todo.todoProject
```

Expected: `lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`, and Firebase app selections matching the two registered identifiers. On Windows, FlutterFire may not attach the iOS plist to the Xcode project; do not create a second Firebase iOS app.

- [ ] **Step 5: Retrieve the existing iOS SDK config when the Windows FlutterFire path does not emit it**

Run `firebase apps:list --project naem-o --json` and parse the existing iOS app without typing its Firebase app ID:

```powershell
$appsResponse = firebase apps:list --project naem-o --json | ConvertFrom-Json
$iosApp = @($appsResponse.result) | Where-Object {
  $_.platform -eq 'IOS' -and
  $_.namespace -eq 'com.bolliverse.todo.todoProject'
}
if ($iosApp.Count -ne 1) {
  throw "Expected one registered iOS app, found $($iosApp.Count)."
}
$iosSdkConfig = firebase apps:sdkconfig IOS $iosApp.appId --project naem-o
```

Add the complete `$iosSdkConfig` plist text to `ios/Runner/GoogleService-Info.plist` with `apply_patch`. Do not print or commit Apple private keys; the Firebase plist contains app configuration, not the Apple private key.

- [ ] **Step 6: Validate generated configuration without exposing token-like values in logs**

Run a PowerShell script that parses JSON/XML and asserts only these identities:

```text
google-services.json project_info.project_id == naem-o
google-services.json client[0].client_info.android_client_info.package_name == com.bolliverse.todo.todo_project
GoogleService-Info.plist PROJECT_ID == naem-o
GoogleService-Info.plist BUNDLE_ID == com.bolliverse.todo.todoProject
```

Expected: four assertions pass. Do not echo API keys or OAuth client IDs.

- [ ] **Step 7: Commit the dependency and generated project configuration**

```powershell
git add .gitignore pubspec.yaml pubspec.lock firebase.json lib/firebase_options.dart android/app/google-services.json ios/Runner/GoogleService-Info.plist
git diff --cached --check
git commit -m "chore: configure Firebase authentication"
```

## Task 2: Replace the persisted provider model with remote Firebase sessions

**Files:**
- Create: `lib/features/auth/data/models/remote_auth_user.dart`
- Create: `lib/features/auth/data/datasources/auth_session_remote_data_source.dart`
- Modify: `lib/features/auth/domain/entities/auth_session.dart`
- Modify: `lib/features/auth/data/repositories/auth_session_repository_impl.dart`
- Modify: `test/features/auth/data/repositories/auth_session_repository_impl_test.dart`
- Delete: `lib/features/auth/data/datasources/auth_session_local_data_source.dart`
- Delete: `lib/features/auth/data/datasources/auth_session_local_data_source_impl.dart`

- [ ] **Step 1: Write repository tests against a fake remote source**

Replace the local-data-source test fake with `FakeAuthSessionRemoteDataSource` and cover these outcomes:

```dart
test('restores uid and provider from the remote user', () async {
  remoteDataSource.restoredUser = const RemoteAuthUser(
    uid: 'firebase-user-1',
    provider: AuthProviderType.apple,
  );

  final result = await repository.restoreSession();

  final session = result.data as AuthenticatedSession;
  expect(session.uid, 'firebase-user-1');
  expect(session.provider, AuthProviderType.apple);
});

test('treats a cancelled sign-in as unauthenticated success', () async {
  remoteDataSource.signedInUser = null;

  final result = await repository.signIn(AuthProviderType.google);

  expect(result.failure, isNull);
  expect(result.data, isA<UnauthenticatedSession>());
});
```

- [ ] **Step 2: Run the repository test and verify RED**

Run:

```powershell
flutter test test/features/auth/data/repositories/auth_session_repository_impl_test.dart --no-pub
```

Expected: compile failure because `RemoteAuthUser` and `AuthSessionRemoteDataSource` do not exist and `AuthenticatedSession` has no `uid`.

- [ ] **Step 3: Add the remote user and data-source contract**

Create `remote_auth_user.dart`:

```dart
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

class RemoteAuthUser {
  final String uid;
  final AuthProviderType provider;

  const RemoteAuthUser({required this.uid, required this.provider});
}
```

Create `auth_session_remote_data_source.dart`:

```dart
import 'package:nae_mo/features/auth/data/models/remote_auth_user.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthSessionRemoteDataSource {
  Future<RemoteAuthUser?> restoreSession();
  Future<RemoteAuthUser?> signIn(AuthProviderType provider);
  Future<void> signOut();
}
```

- [ ] **Step 4: Make Domain sessions uid-aware and repository mapping remote-first**

Use this authenticated session shape:

```dart
final class AuthenticatedSession extends AuthSession {
  final String uid;
  final AuthProviderType provider;

  const AuthenticatedSession({required this.uid, required this.provider});
}
```

Repository success mapping must be centralized:

```dart
AuthSession _toSession(RemoteAuthUser? user) => user == null
    ? const UnauthenticatedSession()
    : AuthenticatedSession(uid: user.uid, provider: user.provider);
```

`restoreSession()` and `signIn()` call the remote source and `_toSession`; `signOut()` awaits the remote source and returns `UnauthenticatedSession`.

- [ ] **Step 5: Update every test fake constructor to provide deterministic uid values**

Use provider-derived fake IDs consistently:

```dart
AuthenticatedSession(
  uid: '${provider.name}-user',
  provider: provider,
)
```

Update `test/widget_test.dart` and `test/features/auth/presentation/viewmodels/auth_view_model_test.dart` in the same step so the suite compiles.

- [ ] **Step 6: Remove the SharedPreferences data source and stale persistence integration test**

Delete the two local data-source files and `test/features/auth/integration/auth_persistence_integration_test.dart`. Verify `rg -n "SharedPreferences|auth.provider|fromStorageValue" lib test pubspec.yaml` returns no matches.

- [ ] **Step 7: Run tests and commit**

```powershell
flutter test test/features/auth/data/repositories/auth_session_repository_impl_test.dart test/features/auth/presentation/viewmodels/auth_view_model_test.dart test/widget_test.dart --no-pub
git add lib/features/auth test/features/auth test/widget_test.dart
git diff --cached --check
git commit -m "feat: model Firebase auth sessions"
```

Expected: selected tests pass.

## Task 3: Add auth-specific error mapping

**Files:**
- Create: `lib/features/auth/data/auth_error_messages.dart`
- Create: `test/features/auth/data/auth_error_messages_test.dart`
- Modify: `lib/core/errors/app_exception.dart`
- Modify: `lib/core/errors/failure.dart`
- Modify: `lib/features/auth/data/repositories/auth_session_repository_impl.dart`

- [ ] **Step 1: Write the pure error mapping tests**

Cover the exact messages:

```dart
expect(firebaseAuthMessage('network-request-failed'),
    '네트워크 연결을 확인하고 다시 시도해 주세요.');
expect(firebaseAuthMessage('operation-not-allowed'),
    '로그인 설정이 완료되지 않았습니다.');
expect(firebaseAuthMessage('user-disabled'), '사용할 수 없는 계정입니다.');
expect(firebaseAuthMessage('account-exists-with-different-credential'),
    '이미 다른 로그인 방법으로 등록된 계정입니다.');
expect(firebaseAuthMessage('unrecognized-code'),
    '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.');
```

Also assert `isFirebaseCancellationCode` is true for `web-context-cancelled`, `canceled`, and `cancelled`, and false for configuration/network errors.

- [ ] **Step 2: Run the mapper test and verify RED**

Run `flutter test test/features/auth/data/auth_error_messages_test.dart --no-pub`.

Expected: compile failure because the mapping functions do not exist.

- [ ] **Step 3: Add auth exception/failure types**

Append:

```dart
class AuthException extends AppException {
  const AuthException(super.message);
}
```

and:

```dart
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
  ]);
}
```

- [ ] **Step 4: Implement pure mapping functions**

```dart
const genericAuthErrorMessage =
    '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.';

String firebaseAuthMessage(String code) => switch (code) {
      'network-request-failed' =>
        '네트워크 연결을 확인하고 다시 시도해 주세요.',
      'operation-not-allowed' ||
      'invalid-credential' ||
      'invalid-oauth-provider' =>
        '로그인 설정이 완료되지 않았습니다.',
      'user-disabled' => '사용할 수 없는 계정입니다.',
      'account-exists-with-different-credential' =>
        '이미 다른 로그인 방법으로 등록된 계정입니다.',
      _ => genericAuthErrorMessage,
    };

bool isFirebaseCancellationCode(String code) => const {
      'web-context-cancelled',
      'canceled',
      'cancelled',
    }.contains(code);
```

- [ ] **Step 5: Map AuthException to AuthFailure in the repository**

Catch `AuthException` before the generic catch and return `AuthFailure(exception.message)`. The generic catch returns `const AuthFailure()`; remove all CacheException/CacheFailure handling from this repository.

- [ ] **Step 6: Run and commit**

```powershell
flutter test test/features/auth/data/auth_error_messages_test.dart test/features/auth/data/repositories/auth_session_repository_impl_test.dart --no-pub
git add lib/core/errors lib/features/auth/data test/features/auth/data
git diff --cached --check
git commit -m "feat: map Firebase authentication errors"
```

## Task 4: Implement testable Firebase and Google SDK gateways

**Files:**
- Create: `lib/features/auth/data/gateways/firebase_auth_gateway.dart`
- Create: `lib/features/auth/data/gateways/google_sign_in_gateway.dart`
- Create: `lib/features/auth/data/datasources/firebase_auth_session_remote_data_source.dart`
- Create: `test/features/auth/data/datasources/firebase_auth_session_remote_data_source_test.dart`

- [ ] **Step 1: Write remote data-source tests using fake gateways**

The fake Firebase gateway exposes `currentUser`, an auth-state stream, Google/Apple sign-in results, and call counters. Cover:

```dart
test('restores the first Firebase auth state', () async {
  firebase.restoredUser = const FirebaseGatewayUser(
    uid: 'restored-user',
    providerIds: {'apple.com'},
  );

  final user = await dataSource.restoreSession();

  expect(user?.uid, 'restored-user');
  expect(user?.provider, AuthProviderType.apple);
});

test('signs Google into Firebase with the Google id token', () async {
  google.idToken = 'test-id-token';
  firebase.googleUser = const FirebaseGatewayUser(
    uid: 'google-user',
    providerIds: {'google.com'},
  );

  final user = await dataSource.signIn(AuthProviderType.google);

  expect(firebase.receivedGoogleIdToken, 'test-id-token');
  expect(user?.provider, AuthProviderType.google);
});

test('returns null when Google authentication is cancelled', () async {
  google.idToken = null;

  final user = await dataSource.signIn(AuthProviderType.google);

  expect(user, isNull);
  expect(firebase.googleSignInCalls, 0);
});
```

Also test Apple provider use, unknown provider IDs, Firebase cancellation (사용자 취소), Google-first logout ordering, Google logout failure preventing Firebase logout, and Apple logout calling Firebase only.

- [ ] **Step 2: Run the data-source test and verify RED**

Run `flutter test test/features/auth/data/datasources/firebase_auth_session_remote_data_source_test.dart --no-pub`.

Expected: compile failure because gateways and implementation do not exist.

- [ ] **Step 3: Create the Firebase gateway contract and implementation**

Use this SDK-neutral record/contract:

```dart
class FirebaseGatewayUser {
  final String uid;
  final Set<String> providerIds;

  const FirebaseGatewayUser({required this.uid, required this.providerIds});
}

abstract interface class FirebaseAuthGateway {
  FirebaseGatewayUser? get currentUser;
  Stream<FirebaseGatewayUser?> authStateChanges();
  Future<FirebaseGatewayUser> signInWithGoogleIdToken(String idToken);
  Future<FirebaseGatewayUser> signInWithApple();
  Future<void> signOut();
}
```

`FirebaseAuthGatewayImpl` wraps `FirebaseAuth`, maps `User.providerData.map((info) => info.providerId).toSet()`, uses `GoogleAuthProvider.credential(idToken: idToken)`, uses `signInWithProvider(AppleAuthProvider())`, and throws `AuthException` if a returned credential has no user or a blank uid.

- [ ] **Step 4: Create the Google gateway with one-time initialization**

```dart
abstract interface class GoogleSignInGateway {
  Future<String?> authenticate();
  Future<void> signOut();
}

class GoogleSignInGatewayImpl implements GoogleSignInGateway {
  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  GoogleSignInGatewayImpl(this._googleSignIn);

  @override
  Future<String?> authenticate() async {
    await (_initialization ??= _googleSignIn.initialize());
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('로그인 설정이 완료되지 않았습니다.');
      }
      return idToken;
    } on GoogleSignInException catch (exception) {
      if (exception.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
```

- [ ] **Step 5: Implement the Firebase remote data source**

Provider mapping must be deterministic:

```dart
AuthProviderType _providerFor(FirebaseGatewayUser user) {
  if (user.providerIds.contains('google.com')) return AuthProviderType.google;
  if (user.providerIds.contains('apple.com')) return AuthProviderType.apple;
  throw const AuthException('지원하지 않는 로그인 계정입니다.');
}
```

Use `authStateChanges().first` for restore. Google login obtains the nullable ID token then calls `signInWithGoogleIdToken`; Apple calls `signInWithApple`. Catch `FirebaseAuthException`, return null for cancellation codes, otherwise throw `AuthException(firebaseAuthMessage(code))`. Catch `GoogleSignInException` and map configuration errors to `로그인 설정이 완료되지 않았습니다.`, interruptions to the generic message. Preserve an existing `AuthException` unchanged.

For sign-out, inspect `firebase.currentUser.providerIds`; call Google sign-out first only for `google.com`, then call Firebase sign-out. Wrap failures in `AuthException('로그아웃하지 못했습니다. 다시 시도해 주세요.')`.

- [ ] **Step 6: Run and commit**

```powershell
dart format lib/features/auth/data test/features/auth/data
flutter test test/features/auth/data/datasources/firebase_auth_session_remote_data_source_test.dart test/features/auth/data/repositories/auth_session_repository_impl_test.dart --no-pub
git add lib/features/auth/data test/features/auth/data
git diff --cached --check
git commit -m "feat: authenticate with Firebase providers"
```

## Task 5: Wire supported platforms and Firebase startup

**Files:**
- Create: `lib/core/platform/firebase_auth_platform.dart`
- Create: `test/core/platform/firebase_auth_platform_test.dart`
- Create: `lib/features/auth/data/datasources/unsupported_auth_session_remote_data_source.dart`
- Modify: `lib/features/auth/auth_providers.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write platform predicate tests**

```dart
expect(isFirebaseAuthPlatform(TargetPlatform.android), isTrue);
expect(isFirebaseAuthPlatform(TargetPlatform.iOS), isTrue);
expect(isFirebaseAuthPlatform(TargetPlatform.windows), isFalse);
expect(isFirebaseAuthPlatform(TargetPlatform.linux), isFalse);
expect(isFirebaseAuthPlatform(TargetPlatform.macOS), isFalse);
expect(isFirebaseAuthPlatform(TargetPlatform.android, isWeb: true), isFalse);
```

- [ ] **Step 2: Run the platform test and verify RED**

Run `flutter test test/core/platform/firebase_auth_platform_test.dart --no-pub`.

Expected: compile failure because `isFirebaseAuthPlatform` does not exist.

- [ ] **Step 3: Implement the pure platform predicate**

```dart
bool isFirebaseAuthPlatform(
  TargetPlatform platform, {
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return false;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

bool get supportsFirebaseAuth =>
    isFirebaseAuthPlatform(defaultTargetPlatform);
```

- [ ] **Step 4: Implement the unsupported-platform data source**

`restoreSession()` returns null, `signOut()` completes successfully, and `signIn()` throws:

```dart
const AuthException(
  'Google 및 Apple 로그인은 Android와 iOS에서 지원됩니다.',
)
```

- [ ] **Step 5: Replace SharedPreferences dependency injection**

Provide `FirebaseAuth.instance`, `GoogleSignIn.instance`, both gateway implementations, and the remote source. In `authSessionRemoteDataSourceProvider`, return the unsupported source before reading Firebase SDK providers when `supportsFirebaseAuth` is false. Keep `authSessionRepositoryProvider` public and overrideable.

- [ ] **Step 6: Initialize Firebase before ProviderScope only on Android/iOS**

Update `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supportsFirebaseAuth) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await initializeDateFormatting('ko', null);
  runApp(const ProviderScope(child: App()));
}
```

- [ ] **Step 7: Run focused and full tests, then commit**

```powershell
dart format lib/main.dart lib/core/platform lib/features/auth/auth_providers.dart lib/features/auth/data/datasources/unsupported_auth_session_remote_data_source.dart test/core/platform
flutter test test/core/platform/firebase_auth_platform_test.dart test/widget_test.dart --no-pub
flutter test --no-pub
git add lib/main.dart lib/core/platform lib/features/auth/auth_providers.dart lib/features/auth/data/datasources/unsupported_auth_session_remote_data_source.dart test/core/platform
git diff --cached --check
git commit -m "feat: initialize Firebase authentication"
```

Expected: 28 baseline tests plus new tests pass.

## Task 6: Update presentation fallbacks and cancellation regressions

**Files:**
- Modify: `lib/features/auth/presentation/viewmodels/auth_view_model.dart`
- Modify: `test/features/auth/presentation/viewmodels/auth_view_model_test.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add cancellation and uid regression tests**

Add a ViewModel test where repository sign-in returns `UnauthenticatedSession`; assert no error, submitting false, and login state retained. Add a widget test tapping Google with the same result; assert both buttons re-enable, the calendar is absent, and no error text is present.

For successful restoration/sign-in, assert both values:

```dart
expect(session.uid, 'apple-user');
expect(session.provider, AuthProviderType.apple);
```

- [ ] **Step 2: Run the focused tests and verify RED where fallback text differs**

Run:

```powershell
flutter test test/features/auth/presentation/viewmodels/auth_view_model_test.dart test/widget_test.dart --no-pub
```

Expected: new cancellation assertions expose any stale error/pending state; auth-specific fallback assertions fail until messages are changed.

- [ ] **Step 3: Replace persistence wording in ViewModel catch fallbacks**

Use:

```text
restore: 로그인 정보를 확인하지 못했습니다.
sign in: 로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.
sign out: 로그아웃하지 못했습니다. 다시 시도해 주세요.
```

Do not add navigation calls; router state remains the only navigation source.

- [ ] **Step 4: Run and commit**

```powershell
dart format lib/features/auth/presentation test/features/auth/presentation test/widget_test.dart
flutter test test/features/auth/presentation/viewmodels/auth_view_model_test.dart test/widget_test.dart --no-pub
git add lib/features/auth/presentation test/features/auth/presentation test/widget_test.dart
git diff --cached --check
git commit -m "test: cover Firebase auth presentation"
```

## Task 7: Configure Android app identity and Firebase build integration

**Files:**
- Modify: `android/settings.gradle`
- Modify: `android/app/build.gradle`
- Create: `android/app/src/main/kotlin/com/bolliverse/todo/todo_project/MainActivity.kt`
- Delete: `android/app/src/main/kotlin/com/example/nae_mo/MainActivity.kt`

- [ ] **Step 1: Add the current official Google services Gradle plugin**

In `android/settings.gradle` plugins:

```groovy
id "com.google.gms.google-services" version "4.5.0" apply false
```

In `android/app/build.gradle` plugins:

```groovy
id "com.google.gms.google-services"
```

- [ ] **Step 2: Apply the registered package and Android 6 minimum**

```groovy
namespace = "com.bolliverse.todo.todo_project"

defaultConfig {
    applicationId = "com.bolliverse.todo.todo_project"
    minSdk = 23
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

- [ ] **Step 3: Move the Android entry point**

Create:

```kotlin
package com.bolliverse.todo.todo_project

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
```

Remove the old package path.

- [ ] **Step 4: Verify package/config consistency and build Android**

Run scripts that assert the Gradle application ID, Kotlin package, and Firebase JSON package all equal `com.bolliverse.todo.todo_project`, then run:

```powershell
flutter build apk --debug --no-pub
```

Expected: exit 0 and `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 5: Commit**

```powershell
git add android
git diff --cached --check
git commit -m "chore: configure Android Firebase auth"
```

## Task 8: Configure the iOS app and Apple entitlement

**Files:**
- Create: `ios/Podfile`
- Create: `ios/Runner/Runner.entitlements`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`

- [ ] **Step 1: Add the standard Flutter Podfile with iOS 15 minimum**

Copy the Flutter 3.24.5 `Podfile-ios-swift` template and set its first active platform line to:

```ruby
platform :ios, '15.0'
```

Keep `use_frameworks!`, `use_modular_headers!`, RunnerTests inheritance, and `flutter_additional_ios_build_settings` from the SDK template.

- [ ] **Step 2: Add the Sign in with Apple entitlement**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.developer.applesignin</key>
  <array>
    <string>Default</string>
  </array>
</dict>
</plist>
```

- [ ] **Step 3: Register iOS Firebase and entitlement files in the Xcode project**

Add `GoogleService-Info.plist` to the Runner group and Resources build phase. Add `Runner.entitlements` to the Runner group. Set all Runner build configurations to:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.bolliverse.todo.todoProject;
CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;
```

Set every existing `IPHONEOS_DEPLOYMENT_TARGET` to `15.0`. Keep RunnerTests bundle IDs derived from `com.bolliverse.todo.todoProject.RunnerTests`.

- [ ] **Step 4: Add the official Google Sign-In iOS values**

Parse `CLIENT_ID` and `REVERSED_CLIENT_ID` from the committed Firebase plist:

```powershell
$firebasePlist = [xml](Get-Content -LiteralPath 'ios\Runner\GoogleService-Info.plist' -Raw -Encoding UTF8)
function Get-PlistStringValue([System.Xml.XmlElement]$dict, [string]$keyName) {
  $nodes = @($dict.ChildNodes)
  for ($index = 0; $index -lt $nodes.Count - 1; $index++) {
    if ($nodes[$index].Name -eq 'key' -and
        $nodes[$index].InnerText -eq $keyName) {
      return $nodes[$index + 1].InnerText
    }
  }
  return $null
}
$clientId = Get-PlistStringValue $firebasePlist.plist.dict 'CLIENT_ID'
$reversedClientId = Get-PlistStringValue $firebasePlist.plist.dict 'REVERSED_CLIENT_ID'
if ([string]::IsNullOrWhiteSpace($clientId) -or
    [string]::IsNullOrWhiteSpace($reversedClientId)) {
  throw 'Google iOS client IDs are missing from Firebase configuration.'
}
```

Use `apply_patch` to add `GIDClientID` with the evaluated `$clientId`, plus `CFBundleURLTypes` → one `Editor` dictionary → `CFBundleURLSchemes` → the evaluated `$reversedClientId`. Re-read `Info.plist` and assert the two committed string values equal the source plist values; no instructional XML comment remains in the actual file.

- [ ] **Step 5: Perform Windows-safe structural validation**

Use PowerShell XML parsing to assert:

```text
Info.plist GIDClientID == GoogleService-Info.plist CLIENT_ID
Info.plist URL scheme == GoogleService-Info.plist REVERSED_CLIENT_ID
GoogleService-Info.plist BUNDLE_ID == com.bolliverse.todo.todoProject
Runner.entitlements contains com.apple.developer.applesignin = Default
project.pbxproj contains the service plist in Resources
project.pbxproj uses bundle ID com.bolliverse.todo.todoProject
all deployment targets are 15.0
```

Do not claim an iOS build on Windows.

- [ ] **Step 6: Commit**

```powershell
git add ios
git diff --cached --check
git commit -m "chore: configure iOS Firebase auth"
```

## Task 9: Document the Apple-owner handoff and run release gates

**Files:**
- Create: `docs/FIREBASE_AUTH_SETUP.md`
- Modify: `docs/superpowers/specs/2026-07-31-firebase-auth-design.md` only if implementation evidence requires a factual correction.

- [ ] **Step 1: Write the durable external-setup checklist**

Document these exact unchecked responsibilities:

```markdown
## Apple 담당자 체크리스트

- [ ] Apple Developer App ID `com.bolliverse.todo.todoProject`에서 Sign in with Apple 활성화
- [ ] Android Apple 로그인을 위한 Services ID 생성
- [ ] Return URL에 `https://naem-o.firebaseapp.com/__/auth/handler` 등록
- [ ] Firebase Authentication Apple 공급자에 Services ID, Team ID, Key ID, private key 설정
- [ ] Xcode Runner target의 Team 및 provisioning profile 갱신
- [ ] 실제 iOS 기기에서 Google 로그인 확인
- [ ] 실제 iOS 기기에서 Apple 로그인 확인

private key 파일과 값은 Git, 이슈, PR 본문에 첨부하지 않는다.
```

Also record Android checks for the registered SHA-1/SHA-256 and real-device Google/Apple flows.

- [ ] **Step 2: Run formatting and static analysis**

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
```

Expected: exit 0 with no new analyzer findings.

- [ ] **Step 3: Run the complete test suite once after the final code change**

```powershell
flutter test --no-pub
```

Expected: all tests pass; no skipped or disabled auth tests.

- [ ] **Step 4: Run the Android build and configuration checks**

```powershell
flutter build apk --debug --no-pub
git diff --check
```

Expected: APK build and whitespace check exit 0.

- [ ] **Step 5: Audit the final diff for scope and sensitive material**

Run `git diff origin/main...HEAD --name-status`, `git status --short`, and targeted searches for private-key PEM headers, OAuth tokens, authorization codes, and accidental email/profile logging. Expected: only the planned auth/config/docs files; no Apple private key or token material.

- [ ] **Step 6: Commit documentation**

```powershell
git add docs/FIREBASE_AUTH_SETUP.md docs/superpowers/specs/2026-07-31-firebase-auth-design.md
git diff --cached --check
git commit -m "docs: document Firebase auth setup"
```

- [ ] **Step 7: Push and open a draft PR**

```powershell
git push -u origin codex/firebase-auth
```

Create a draft PR targeting `main`. The PR body must state:

- Google and Apple Firebase Auth are implemented for Android/iOS.
- Automated tests, analysis, and Android debug build results with exact counts.
- Whether Android real-device Google/Apple flows were actually exercised.
- iOS build/sign-in is unverified from Windows.
- The full Apple-owner checklist, with incomplete items left unchecked.
- No private key, OAuth token, email, or profile data is stored in Git.

## Official sources used by this plan

- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Firebase Auth Flutter startup and auth state: https://firebase.google.com/docs/auth/flutter/start
- Firebase Google and Apple federated auth: https://firebase.google.com/docs/auth/flutter/federated-auth
- Firebase Auth error handling: https://firebase.google.com/docs/auth/flutter/errors
- Firebase Android setup: https://firebase.google.com/docs/android/setup
- FlutterFire CLI: https://github.com/invertase/flutterfire_cli
- google_sign_in: https://pub.dev/packages/google_sign_in
- google_sign_in iOS setup: https://pub.dev/packages/google_sign_in_ios

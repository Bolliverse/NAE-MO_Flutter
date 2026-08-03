import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/features/auth/data/datasources/firebase_auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/gateways/firebase_auth_gateway.dart';
import 'package:nae_mo/features/auth/data/gateways/google_sign_in_gateway.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

void main() {
  late _FakeFirebaseAuthGateway firebase;
  late _FakeGoogleSignInGateway google;
  late FirebaseAuthSessionRemoteDataSource dataSource;

  setUp(() {
    firebase = _FakeFirebaseAuthGateway();
    google = _FakeGoogleSignInGateway();
    dataSource = FirebaseAuthSessionRemoteDataSource(firebase, google);
  });

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
    expect(user?.uid, 'google-user');
    expect(user?.provider, AuthProviderType.google);
  });

  test('returns null when Google authentication is cancelled', () async {
    google.idToken = null;

    final user = await dataSource.signIn(AuthProviderType.google);

    expect(user, isNull);
    expect(firebase.googleSignInCalls, 0);
  });

  test('uses the native Apple provider through Firebase', () async {
    firebase.appleUser = const FirebaseGatewayUser(
      uid: 'apple-user',
      providerIds: {'apple.com'},
    );

    final user = await dataSource.signIn(AuthProviderType.apple);

    expect(firebase.appleSignInCalls, 1);
    expect(user?.provider, AuthProviderType.apple);
  });

  test('rejects a Firebase user with an unknown provider', () async {
    firebase.restoredUser = const FirebaseGatewayUser(
      uid: 'password-user',
      providerIds: {'password'},
    );

    expect(
      dataSource.restoreSession,
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '지원하지 않는 로그인 계정입니다.',
        ),
      ),
    );
  });

  test('returns null when Firebase reports provider cancellation', () async {
    firebase.signInException = FirebaseAuthException(code: 'canceled');

    final user = await dataSource.signIn(AuthProviderType.apple);

    expect(user, isNull);
  });

  test('maps Firebase failures to an AuthException message', () async {
    firebase.signInException =
        FirebaseAuthException(code: 'network-request-failed');

    expect(
      () => dataSource.signIn(AuthProviderType.apple),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '네트워크 연결을 확인하고 다시 시도해 주세요.',
        ),
      ),
    );
  });

  test('signs Google out before signing Firebase out', () async {
    firebase.current = const FirebaseGatewayUser(
      uid: 'google-user',
      providerIds: {'google.com'},
    );
    google.order = firebase.order;

    await dataSource.signOut();

    expect(firebase.order, ['google', 'firebase']);
  });

  test('does not sign Firebase out when Google sign-out fails', () async {
    firebase.current = const FirebaseGatewayUser(
      uid: 'google-user',
      providerIds: {'google.com'},
    );
    google.signOutException = StateError('google failed');

    expect(
      dataSource.signOut,
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          '로그아웃하지 못했습니다. 다시 시도해 주세요.',
        ),
      ),
    );
    expect(firebase.signOutCalls, 0);
  });

  test('Apple logout calls Firebase only', () async {
    firebase.current = const FirebaseGatewayUser(
      uid: 'apple-user',
      providerIds: {'apple.com'},
    );
    google.order = firebase.order;

    await dataSource.signOut();

    expect(firebase.order, ['firebase']);
  });
}

class _FakeFirebaseAuthGateway implements FirebaseAuthGateway {
  FirebaseGatewayUser? current;
  FirebaseGatewayUser? restoredUser;
  FirebaseGatewayUser? googleUser;
  FirebaseGatewayUser? appleUser;
  FirebaseAuthException? signInException;
  String? receivedGoogleIdToken;
  int googleSignInCalls = 0;
  int appleSignInCalls = 0;
  int signOutCalls = 0;
  final List<String> order = [];

  @override
  FirebaseGatewayUser? get currentUser => current;

  @override
  Stream<FirebaseGatewayUser?> authStateChanges() => Stream.value(restoredUser);

  @override
  Future<FirebaseGatewayUser> signInWithGoogleIdToken(String idToken) async {
    googleSignInCalls++;
    receivedGoogleIdToken = idToken;
    final error = signInException;
    if (error != null) throw error;
    return googleUser!;
  }

  @override
  Future<FirebaseGatewayUser> signInWithApple() async {
    appleSignInCalls++;
    final error = signInException;
    if (error != null) throw error;
    return appleUser!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    order.add('firebase');
  }
}

class _FakeGoogleSignInGateway implements GoogleSignInGateway {
  String? idToken;
  Object? signOutException;
  List<String>? order;

  @override
  Future<String?> authenticate() async => idToken;

  @override
  Future<void> signOut() async {
    final error = signOutException;
    if (error != null) throw error;
    order?.add('google');
  }
}

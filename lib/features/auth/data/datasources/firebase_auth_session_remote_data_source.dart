import 'package:firebase_auth/firebase_auth.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/features/auth/data/auth_error_messages.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/gateways/firebase_auth_gateway.dart';
import 'package:nae_mo/features/auth/data/gateways/google_sign_in_gateway.dart';
import 'package:nae_mo/features/auth/data/models/remote_auth_user.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

class FirebaseAuthSessionRemoteDataSource
    implements AuthSessionRemoteDataSource {
  final FirebaseAuthGateway _firebase;
  final GoogleSignInGateway _google;

  const FirebaseAuthSessionRemoteDataSource(this._firebase, this._google);

  @override
  Future<RemoteAuthUser?> restoreSession() => _guard(() async {
        final user = await _firebase.authStateChanges().first;
        return _mapUser(user);
      });

  @override
  Future<RemoteAuthUser?> signIn(AuthProviderType provider) => _guard(() async {
        final FirebaseGatewayUser? user;
        switch (provider) {
          case AuthProviderType.google:
            final idToken = await _google.authenticate();
            if (idToken == null) return null;
            user = await _firebase.signInWithGoogleIdToken(idToken);
            break;
          case AuthProviderType.apple:
            user = await _firebase.signInWithApple();
            break;
        }
        return _mapUser(user);
      });

  @override
  Future<void> signOut() async {
    try {
      if (_firebase.currentUser?.providerIds.contains('google.com') ?? false) {
        await _google.signOut();
      }
      await _firebase.signOut();
    } on Object {
      throw const AuthException(
        '로그아웃하지 못했습니다. 다시 시도해 주세요.',
      );
    }
  }

  Future<RemoteAuthUser?> _guard(
    Future<RemoteAuthUser?> Function() operation,
  ) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (exception) {
      if (isFirebaseCancellationCode(exception.code)) return null;
      throw AuthException(firebaseAuthMessage(exception.code));
    }
  }

  RemoteAuthUser? _mapUser(FirebaseGatewayUser? user) {
    if (user == null) return null;
    return RemoteAuthUser(uid: user.uid, provider: _providerFor(user));
  }

  AuthProviderType _providerFor(FirebaseGatewayUser user) {
    if (user.providerIds.contains('google.com')) return AuthProviderType.google;
    if (user.providerIds.contains('apple.com')) return AuthProviderType.apple;
    throw const AuthException('지원하지 않는 로그인 계정입니다.');
  }
}

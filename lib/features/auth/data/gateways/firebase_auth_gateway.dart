import 'package:firebase_auth/firebase_auth.dart';
import 'package:nae_mo/core/errors/app_exception.dart';

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

class FirebaseAuthGatewayImpl implements FirebaseAuthGateway {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthGatewayImpl(this._firebaseAuth);

  @override
  FirebaseGatewayUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Stream<FirebaseGatewayUser?> authStateChanges() =>
      _firebaseAuth.authStateChanges().map(_mapUser);

  @override
  Future<FirebaseGatewayUser> signInWithGoogleIdToken(String idToken) async {
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _firebaseAuth.signInWithCredential(credential);
    return _requireUser(result.user);
  }

  @override
  Future<FirebaseGatewayUser> signInWithApple() async {
    final result = await _firebaseAuth.signInWithProvider(AppleAuthProvider());
    return _requireUser(result.user);
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  FirebaseGatewayUser _requireUser(User? user) {
    final mapped = _mapUser(user);
    if (mapped == null) {
      throw const AuthException(
        '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
    return mapped;
  }

  FirebaseGatewayUser? _mapUser(User? user) {
    if (user == null) return null;
    final uid = user.uid.trim();
    if (uid.isEmpty) return null;
    return FirebaseGatewayUser(
      uid: uid,
      providerIds: user.providerData
          .map((provider) => provider.providerId)
          .where((providerId) => providerId.isNotEmpty)
          .toSet(),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nae_mo/core/errors/app_exception.dart';

abstract interface class GoogleSignInGateway {
  Future<String?> authenticate();

  Future<void> signOut();
}

class GoogleSignInGatewayImpl implements GoogleSignInGateway {
  final GoogleSignIn _googleSignIn;

  GoogleSignInGatewayImpl(this._googleSignIn);

  @override
  Future<String?> authenticate() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final idToken = (await account.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('로그인 설정이 완료되지 않았습니다.');
      }
      return idToken;
    } on PlatformException catch (exception) {
      if (exception.code == GoogleSignIn.kSignInCanceledError) return null;
      if (exception.code == GoogleSignIn.kNetworkError) {
        throw const AuthException(
          '네트워크 연결을 확인하고 다시 시도해 주세요.',
        );
      }
      if (exception.code == GoogleSignIn.kSignInFailedError) {
        throw const AuthException('로그인 설정이 완료되지 않았습니다.');
      }
      throw const AuthException(
        '로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

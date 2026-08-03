import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/models/remote_auth_user.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

class UnsupportedAuthSessionRemoteDataSource
    implements AuthSessionRemoteDataSource {
  const UnsupportedAuthSessionRemoteDataSource();

  @override
  Future<RemoteAuthUser?> restoreSession() async => null;

  @override
  Future<RemoteAuthUser?> signIn(AuthProviderType provider) {
    throw const AuthException(
      'Google 및 Apple 로그인은 Android와 iOS에서 지원됩니다.',
    );
  }

  @override
  Future<void> signOut() async {}
}

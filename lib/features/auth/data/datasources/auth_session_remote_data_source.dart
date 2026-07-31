import 'package:nae_mo/features/auth/data/models/remote_auth_user.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthSessionRemoteDataSource {
  Future<RemoteAuthUser?> restoreSession();

  Future<RemoteAuthUser?> signIn(AuthProviderType provider);

  Future<void> signOut();
}

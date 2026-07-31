import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthSessionLocalDataSource {
  Future<AuthProviderType?> readProvider();

  Future<void> writeProvider(AuthProviderType provider);

  Future<void> clearProvider();
}

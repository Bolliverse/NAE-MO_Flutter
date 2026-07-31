import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

abstract interface class AuthSessionRepository {
  Future<Result<AuthSession>> restoreSession();

  Future<Result<AuthSession>> signIn(AuthProviderType provider);

  Future<Result<AuthSession>> signOut();
}

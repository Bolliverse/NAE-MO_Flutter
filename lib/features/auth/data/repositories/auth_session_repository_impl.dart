import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_local_data_source.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';

class AuthSessionRepositoryImpl implements AuthSessionRepository {
  final AuthSessionLocalDataSource _localDataSource;

  const AuthSessionRepositoryImpl(this._localDataSource);

  @override
  Future<Result<AuthSession>> restoreSession() => _guard(() async {
        final provider = await _localDataSource.readProvider();
        return provider == null
            ? const UnauthenticatedSession()
            : AuthenticatedSession(provider);
      });

  @override
  Future<Result<AuthSession>> signIn(AuthProviderType provider) =>
      _guard(() async {
        await _localDataSource.writeProvider(provider);
        return AuthenticatedSession(provider);
      });

  @override
  Future<Result<AuthSession>> signOut() => _guard(() async {
        await _localDataSource.clearProvider();
        return const UnauthenticatedSession();
      });

  Future<Result<AuthSession>> _guard(
    Future<AuthSession> Function() operation,
  ) async {
    try {
      return success(await operation());
    } on CacheException catch (exception) {
      return fail(CacheFailure(exception.message));
    } on Object {
      return fail(const CacheFailure());
    }
  }
}

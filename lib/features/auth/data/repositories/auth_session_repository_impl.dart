import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/models/remote_auth_user.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';

class AuthSessionRepositoryImpl implements AuthSessionRepository {
  final AuthSessionRemoteDataSource _remoteDataSource;

  const AuthSessionRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AuthSession>> restoreSession() => _guard(() async {
        final user = await _remoteDataSource.restoreSession();
        return _toSession(user);
      });

  @override
  Future<Result<AuthSession>> signIn(AuthProviderType provider) =>
      _guard(() async {
        final user = await _remoteDataSource.signIn(provider);
        return _toSession(user);
      });

  @override
  Future<Result<AuthSession>> signOut() => _guard(() async {
        await _remoteDataSource.signOut();
        return const UnauthenticatedSession();
      });

  AuthSession _toSession(RemoteAuthUser? user) => user == null
      ? const UnauthenticatedSession()
      : AuthenticatedSession(uid: user.uid, provider: user.provider);

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

import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_remote_data_source.dart';
import 'package:nae_mo/features/auth/data/models/remote_auth_user.dart';
import 'package:nae_mo/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

void main() {
  late _FakeAuthSessionRemoteDataSource remoteDataSource;
  late AuthSessionRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _FakeAuthSessionRemoteDataSource();
    repository = AuthSessionRepositoryImpl(remoteDataSource);
  });

  group('restoreSession', () {
    test('returns unauthenticated when Firebase has no current user', () async {
      final result = await repository.restoreSession();

      expect(result.failure, isNull);
      expect(result.data, isA<UnauthenticatedSession>());
    });

    test('restores uid and provider from the remote user', () async {
      remoteDataSource.restoredUser = const RemoteAuthUser(
        uid: 'firebase-user-1',
        provider: AuthProviderType.apple,
      );

      final result = await repository.restoreSession();

      final session = result.data as AuthenticatedSession;
      expect(session.uid, 'firebase-user-1');
      expect(session.provider, AuthProviderType.apple);
    });
  });

  group('signIn', () {
    test('maps the signed-in remote user to an authenticated session',
        () async {
      remoteDataSource.signedInUser = const RemoteAuthUser(
        uid: 'google-user',
        provider: AuthProviderType.google,
      );

      final result = await repository.signIn(AuthProviderType.google);

      expect(remoteDataSource.requestedProvider, AuthProviderType.google);
      final session = result.data as AuthenticatedSession;
      expect(session.uid, 'google-user');
      expect(session.provider, AuthProviderType.google);
    });

    test('treats a cancelled sign-in as unauthenticated success', () async {
      remoteDataSource.signedInUser = null;

      final result = await repository.signIn(AuthProviderType.google);

      expect(result.failure, isNull);
      expect(result.data, isA<UnauthenticatedSession>());
    });
  });

  test('signOut delegates remotely before returning unauthenticated', () async {
    final result = await repository.signOut();

    expect(remoteDataSource.signOutCalls, 1);
    expect(result.failure, isNull);
    expect(result.data, isA<UnauthenticatedSession>());
  });
}

class _FakeAuthSessionRemoteDataSource implements AuthSessionRemoteDataSource {
  RemoteAuthUser? restoredUser;
  RemoteAuthUser? signedInUser;
  AuthProviderType? requestedProvider;
  int signOutCalls = 0;

  @override
  Future<RemoteAuthUser?> restoreSession() async => restoredUser;

  @override
  Future<RemoteAuthUser?> signIn(AuthProviderType provider) async {
    requestedProvider = provider;
    return signedInUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

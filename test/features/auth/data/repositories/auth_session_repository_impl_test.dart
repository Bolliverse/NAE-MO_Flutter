import 'package:flutter_test/flutter_test.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/features/auth/data/datasources/auth_session_local_data_source.dart';
import 'package:nae_mo/features/auth/data/repositories/auth_session_repository_impl.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';

void main() {
  late _FakeAuthSessionLocalDataSource localDataSource;
  late AuthSessionRepositoryImpl repository;

  setUp(() {
    localDataSource = _FakeAuthSessionLocalDataSource();
    repository = AuthSessionRepositoryImpl(localDataSource);
  });

  group('restoreSession', () {
    test('returns unauthenticated when no provider is stored', () async {
      final result = await repository.restoreSession();

      expect(result.failure, isNull);
      expect(result.data, isA<UnauthenticatedSession>());
    });

    for (final provider in AuthProviderType.values) {
      test('restores an authenticated ${provider.name} session', () async {
        localDataSource.storedProvider = provider;

        final result = await repository.restoreSession();

        expect(result.failure, isNull);
        final session = result.data as AuthenticatedSession;
        expect(session.provider, provider);
      });
    }

    test('maps a cache exception to CacheFailure', () async {
      localDataSource.readException = const CacheException('read failed');

      final result = await repository.restoreSession();

      expect(result.data, isNull);
      expect(result.failure, const CacheFailure('read failed'));
    });
  });

  group('signIn', () {
    test('persists the provider before returning an authenticated session',
        () async {
      final result = await repository.signIn(AuthProviderType.google);

      expect(localDataSource.writeCalls, 1);
      expect(localDataSource.storedProvider, AuthProviderType.google);
      final session = result.data as AuthenticatedSession;
      expect(session.provider, AuthProviderType.google);
    });

    test('does not report success when persistence fails', () async {
      localDataSource.writeException = const CacheException('write failed');

      final result = await repository.signIn(AuthProviderType.apple);

      expect(result.data, isNull);
      expect(result.failure, const CacheFailure('write failed'));
      expect(localDataSource.storedProvider, isNull);
    });
  });

  group('signOut', () {
    test('clears the provider before returning unauthenticated', () async {
      localDataSource.storedProvider = AuthProviderType.apple;

      final result = await repository.signOut();

      expect(localDataSource.clearCalls, 1);
      expect(localDataSource.storedProvider, isNull);
      expect(result.data, isA<UnauthenticatedSession>());
    });

    test('keeps the session stored when clearing fails', () async {
      localDataSource
        ..storedProvider = AuthProviderType.apple
        ..clearException = const CacheException('clear failed');

      final result = await repository.signOut();

      expect(result.data, isNull);
      expect(result.failure, const CacheFailure('clear failed'));
      expect(localDataSource.storedProvider, AuthProviderType.apple);
    });
  });
}

class _FakeAuthSessionLocalDataSource implements AuthSessionLocalDataSource {
  AuthProviderType? storedProvider;
  CacheException? readException;
  CacheException? writeException;
  CacheException? clearException;
  int writeCalls = 0;
  int clearCalls = 0;

  @override
  Future<AuthProviderType?> readProvider() async {
    final exception = readException;
    if (exception != null) throw exception;
    return storedProvider;
  }

  @override
  Future<void> writeProvider(AuthProviderType provider) async {
    writeCalls++;
    final exception = writeException;
    if (exception != null) throw exception;
    storedProvider = provider;
  }

  @override
  Future<void> clearProvider() async {
    clearCalls++;
    final exception = clearException;
    if (exception != null) throw exception;
    storedProvider = null;
  }
}

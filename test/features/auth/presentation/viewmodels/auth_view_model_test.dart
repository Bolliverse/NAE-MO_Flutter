import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide fail;
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/auth_providers.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:nae_mo/features/auth/presentation/states/auth_state.dart';
import 'package:nae_mo/features/auth/presentation/viewmodels/auth_view_model.dart';

void main() {
  test('starts loading and restores an unauthenticated session', () async {
    final restoreCompleter = Completer<Result<AuthSession>>();
    final repository = _FakeAuthSessionRepository(
      onRestore: () => restoreCompleter.future,
    );
    final container = _createContainer(repository);

    expect(
        container.read(authViewModelProvider), isA<AsyncLoading<AuthState>>());

    restoreCompleter.complete(success(const UnauthenticatedSession()));
    final state = await container.read(authViewModelProvider.future);

    expect(state.session, isA<UnauthenticatedSession>());
    expect(state.isSubmitting, isFalse);
  });

  test('restores an authenticated session', () async {
    final repository = _FakeAuthSessionRepository(
      restoreResult: success(
        const AuthenticatedSession(AuthProviderType.apple),
      ),
    );
    final container = _createContainer(repository);

    final state = await container.read(authViewModelProvider.future);

    final session = state.session as AuthenticatedSession;
    expect(session.provider, AuthProviderType.apple);
  });

  test('signs in once while duplicate taps are ignored', () async {
    final signInCompleter = Completer<Result<AuthSession>>();
    final repository = _FakeAuthSessionRepository(
      onSignIn: (_) => signInCompleter.future,
    );
    final container = _createContainer(repository);
    await container.read(authViewModelProvider.future);

    final notifier = container.read(authViewModelProvider.notifier);
    final pendingSignIn = notifier.signIn(AuthProviderType.google);
    await Future<void>.delayed(Duration.zero);

    final submitting = container.read(authViewModelProvider).requireValue;
    expect(submitting.isSubmitting, isTrue);
    expect(submitting.pendingProvider, AuthProviderType.google);

    await notifier.signIn(AuthProviderType.apple);
    expect(repository.signInCalls, 1);

    signInCompleter.complete(
      success(const AuthenticatedSession(AuthProviderType.google)),
    );
    await pendingSignIn;

    final signedIn = container.read(authViewModelProvider).requireValue;
    expect(signedIn.isSubmitting, isFalse);
    expect(signedIn.pendingProvider, isNull);
    final session = signedIn.session as AuthenticatedSession;
    expect(session.provider, AuthProviderType.google);
  });

  test('keeps the old session when sign-in fails', () async {
    final repository = _FakeAuthSessionRepository(
      signInResult: fail(const CacheFailure('로그인 저장 실패')),
    );
    final container = _createContainer(repository);
    await container.read(authViewModelProvider.future);

    await container
        .read(authViewModelProvider.notifier)
        .signIn(AuthProviderType.apple);

    final state = container.read(authViewModelProvider).requireValue;
    expect(state.session, isA<UnauthenticatedSession>());
    expect(state.isSubmitting, isFalse);
    expect(state.errorMessage, '로그인 저장 실패');
  });

  test('signs out to an unauthenticated session', () async {
    final repository = _FakeAuthSessionRepository(
      restoreResult: success(
        const AuthenticatedSession(AuthProviderType.google),
      ),
    );
    final container = _createContainer(repository);
    await container.read(authViewModelProvider.future);

    await container.read(authViewModelProvider.notifier).signOut();

    final state = container.read(authViewModelProvider).requireValue;
    expect(state.session, isA<UnauthenticatedSession>());
    expect(state.isSubmitting, isFalse);
    expect(repository.signOutCalls, 1);
  });

  test('keeps the authenticated session when sign-out fails', () async {
    final repository = _FakeAuthSessionRepository(
      restoreResult: success(
        const AuthenticatedSession(AuthProviderType.apple),
      ),
      signOutResult: fail(const CacheFailure('로그아웃 저장 실패')),
    );
    final container = _createContainer(repository);
    await container.read(authViewModelProvider.future);

    await container.read(authViewModelProvider.notifier).signOut();

    final state = container.read(authViewModelProvider).requireValue;
    final session = state.session as AuthenticatedSession;
    expect(session.provider, AuthProviderType.apple);
    expect(state.isSubmitting, isFalse);
    expect(state.errorMessage, '로그아웃 저장 실패');
  });
}

ProviderContainer _createContainer(AuthSessionRepository repository) {
  final container = ProviderContainer(
    overrides: [
      authSessionRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  final Future<Result<AuthSession>> Function()? onRestore;
  final Future<Result<AuthSession>> Function(AuthProviderType provider)?
      onSignIn;
  final Result<AuthSession> restoreResult;
  final Result<AuthSession> signInResult;
  final Result<AuthSession> signOutResult;

  int signInCalls = 0;
  int signOutCalls = 0;

  _FakeAuthSessionRepository({
    this.onRestore,
    this.onSignIn,
    Result<AuthSession>? restoreResult,
    Result<AuthSession>? signInResult,
    Result<AuthSession>? signOutResult,
  })  : restoreResult = restoreResult ??
            success<AuthSession>(const UnauthenticatedSession()),
        signInResult = signInResult ??
            success<AuthSession>(
              const AuthenticatedSession(AuthProviderType.google),
            ),
        signOutResult = signOutResult ??
            success<AuthSession>(const UnauthenticatedSession());

  @override
  Future<Result<AuthSession>> restoreSession() async =>
      onRestore?.call() ?? restoreResult;

  @override
  Future<Result<AuthSession>> signIn(AuthProviderType provider) async {
    signInCalls++;
    return onSignIn?.call(provider) ?? signInResult;
  }

  @override
  Future<Result<AuthSession>> signOut() async {
    signOutCalls++;
    return signOutResult;
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide fail;
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nae_mo/app.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/router/app_router.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/auth_providers.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_provider.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart' as domain;
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko', null));

  testWidgets('shows login when no persisted session exists', (tester) async {
    final authRepository = _FakeAuthSessionRepository();

    await _pumpApp(tester, authRepository);

    expect(find.text('NAE MO'), findsOneWidget);
    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(find.byKey(const Key('appleSignInButton')), findsOneWidget);
  });

  testWidgets('protects a direct calendar route while signed out',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository();
    await _pumpApp(tester, authRepository);

    _routerOf(tester).go(AppRoutes.day);
    await tester.pumpAndSettle();

    expect(find.text('NAE MO'), findsOneWidget);
    expect(find.text('Task Dock'), findsNothing);
  });

  for (final provider in AuthProviderType.values) {
    testWidgets('${provider.name} login opens the day calendar',
        (tester) async {
      final authRepository = _FakeAuthSessionRepository();
      await _pumpApp(tester, authRepository);

      await tester.tap(
        find.byKey(
          Key('${provider.name}SignInButton'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authRepository.storedProvider, provider);
      expect(find.text('Task Dock'), findsOneWidget);
      expect(find.text('NAE MO'), findsNothing);
    });
  }

  testWidgets('restores a saved session without flashing login',
      (tester) async {
    final restoreCompleter = Completer<Result<AuthSession>>();
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.google,
      restoreCompleter: restoreCompleter,
    );

    await _pumpApp(tester, authRepository, settle: false);
    await tester.pump();

    expect(find.bySemanticsLabel('로그인 정보 확인 중'), findsOneWidget);
    expect(find.text('NAE MO'), findsNothing);

    restoreCompleter.complete(
      success(
        const AuthenticatedSession(AuthProviderType.google),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task Dock'), findsOneWidget);
    expect(find.text('NAE MO'), findsNothing);
  });

  testWidgets('redirects an authenticated login route to the day calendar',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.apple,
    );
    await _pumpApp(tester, authRepository);

    _routerOf(tester).go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('Task Dock'), findsOneWidget);
    expect(find.text('NAE MO'), findsNothing);
  });

  testWidgets('logout clears the session and returns to login', (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.google,
    );
    await _pumpApp(tester, authRepository);

    await _tapLogout(tester);

    expect(authRepository.storedProvider, isNull);
    expect(find.text('NAE MO'), findsOneWidget);
    expect(find.text('Task Dock'), findsNothing);
  });

  testWidgets('failed login remains on login and shows the error',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      signInFailure: const CacheFailure('로그인 저장 실패'),
    );
    await _pumpApp(tester, authRepository);

    await tester.tap(find.byKey(const Key('googleSignInButton')));
    await tester.pumpAndSettle();

    expect(find.text('NAE MO'), findsOneWidget);
    expect(find.text('로그인 저장 실패'), findsOneWidget);
  });

  testWidgets('failed logout stays on the calendar and shows a SnackBar',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.apple,
      signOutFailure: const CacheFailure('로그아웃 저장 실패'),
    );
    await _pumpApp(tester, authRepository);

    await _tapLogout(tester);

    expect(authRepository.storedProvider, AuthProviderType.apple);
    expect(find.text('Task Dock'), findsOneWidget);
    expect(find.text('로그아웃 저장 실패'), findsOneWidget);
  });

  testWidgets('mobile calendar moves view switching into the overflow menu',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.google,
    );

    await _pumpApp(tester, authRepository);

    expect(tester.takeException(), isNull);
    expect(find.byType(SegmentedButton), findsNothing);

    await tester.tap(find.byKey(const Key('calendarMoreMenu')));
    await tester.pumpAndSettle();

    expect(find.text('일 보기'), findsOneWidget);
    expect(find.text('주 보기'), findsOneWidget);
    expect(find.text('월 보기'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
  });

  testWidgets('brand buttons expose semantics and lock during sign-in',
      (tester) async {
    final signInCompleter = Completer<Result<AuthSession>>();
    final authRepository = _FakeAuthSessionRepository(
      signInCompleter: signInCompleter,
    );
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester, authRepository);

    expect(
      tester.getSemantics(find.byKey(const Key('googleSignInButton'))),
      matchesSemantics(
        label: 'Google로 로그인',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await tester.tap(find.byKey(const Key('googleSignInButton')));
    await tester.pump();

    expect(
      tester.getSemantics(find.byKey(const Key('appleSignInButton'))),
      matchesSemantics(
        label: 'Apple로 로그인',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );

    await tester.tap(find.byKey(const Key('appleSignInButton')));
    expect(authRepository.signInCalls, 1);

    signInCompleter.complete(
      success(
        const AuthenticatedSession(AuthProviderType.google),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Task Dock'), findsOneWidget);
    semantics.dispose();
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  _FakeAuthSessionRepository authRepository, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionRepositoryProvider.overrideWithValue(authRepository),
        taskRepositoryProvider.overrideWithValue(_EmptyTaskRepository()),
      ],
      child: const App(),
    ),
  );

  if (settle) await tester.pumpAndSettle();
}

GoRouter _routerOf(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(App)),
    listen: false,
  );
  return container.read(appRouterProvider);
}

Future<void> _tapLogout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('calendarMoreMenu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('로그아웃'));
  await tester.pumpAndSettle();
}

class _FakeAuthSessionRepository implements AuthSessionRepository {
  AuthProviderType? storedProvider;
  final Completer<Result<AuthSession>>? restoreCompleter;
  final Completer<Result<AuthSession>>? signInCompleter;
  final Failure? signInFailure;
  final Failure? signOutFailure;

  int signInCalls = 0;

  _FakeAuthSessionRepository({
    this.storedProvider,
    this.restoreCompleter,
    this.signInCompleter,
    this.signInFailure,
    this.signOutFailure,
  });

  @override
  Future<Result<AuthSession>> restoreSession() async {
    final completer = restoreCompleter;
    if (completer != null) return completer.future;
    return success(_sessionFor(storedProvider));
  }

  @override
  Future<Result<AuthSession>> signIn(AuthProviderType provider) async {
    signInCalls++;
    final completer = signInCompleter;
    final result = completer == null
        ? signInFailure == null
            ? success<AuthSession>(AuthenticatedSession(provider))
            : fail<AuthSession>(signInFailure!)
        : await completer.future;

    if (result.data case AuthenticatedSession()) {
      storedProvider = provider;
    }
    return result;
  }

  @override
  Future<Result<AuthSession>> signOut() async {
    final failure = signOutFailure;
    if (failure != null) return fail(failure);
    storedProvider = null;
    return success(const UnauthenticatedSession());
  }

  AuthSession _sessionFor(AuthProviderType? provider) {
    return provider == null
        ? const UnauthenticatedSession()
        : AuthenticatedSession(provider);
  }
}

class _EmptyTaskRepository implements TaskRepository {
  @override
  Future<Result<List<domain.Task>>> getTasksByDate(DateTime date) async =>
      success(const []);

  @override
  Future<Result<List<domain.Task>>> getTasksByRange(
    DateTime start,
    DateTime end,
  ) async =>
      success(const []);

  @override
  Future<Result<List<domain.Task>>> getUnscheduledTasks() async =>
      success(const []);

  @override
  Future<Result<domain.Task>> createTask(CreateTaskParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<domain.Task>> updateTask(UpdateTaskParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteTask(String id) => throw UnimplementedError();

  @override
  Future<Result<domain.Task>> toggleComplete(String id) =>
      throw UnimplementedError();
}

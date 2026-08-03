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
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_today_overview_use_case.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
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

    _routerOf(tester).go(AppRoutes.today);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(find.byKey(const Key('todayContent')), findsNothing);
  });

  for (final provider in AuthProviderType.values) {
    testWidgets('${provider.name} login opens Today', (tester) async {
      final authRepository = _FakeAuthSessionRepository();
      await _pumpApp(tester, authRepository);

      await tester.tap(
        find.byKey(
          Key('${provider.name}SignInButton'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authRepository.storedProvider, provider);
      expect(find.byKey(const Key('todayContent')), findsOneWidget);
      expect(_routerOf(tester).routeInformationProvider.value.uri.path,
          AppRoutes.today);
      expect(find.byKey(const Key('googleSignInButton')), findsNothing);
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
        const AuthenticatedSession(
          uid: 'google-user',
          provider: AuthProviderType.google,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todayContent')), findsOneWidget);
    expect(_routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.today);
    expect(find.byKey(const Key('googleSignInButton')), findsNothing);
  });

  testWidgets('redirects an authenticated login route to Today',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.apple,
    );
    await _pumpApp(tester, authRepository);

    _routerOf(tester).go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todayContent')), findsOneWidget);
    expect(_routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.today);
    expect(find.byKey(const Key('googleSignInButton')), findsNothing);
  });

  testWidgets('logout clears the session and returns to login', (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.google,
    );
    await _pumpApp(tester, authRepository);

    await _tapLogout(tester);

    expect(authRepository.storedProvider, isNull);
    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(find.byKey(const Key('todayContent')), findsNothing);
  });

  testWidgets('failed login remains on login and shows the error',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      signInFailure: const AuthFailure('로그인 실패'),
    );
    await _pumpApp(tester, authRepository);

    await tester.tap(find.byKey(const Key('googleSignInButton')));
    await tester.pumpAndSettle();

    expect(find.text('NAE MO'), findsOneWidget);
    expect(find.text('로그인 실패'), findsOneWidget);
  });

  testWidgets('cancelled Google login stays ready without an error',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(cancelSignIn: true);
    final semantics = tester.ensureSemantics();
    await _pumpApp(tester, authRepository);

    await tester.tap(find.byKey(const Key('googleSignInButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('todayContent')), findsNothing);
    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(
      find.text('로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.'),
      findsNothing,
    );
    expect(
      tester.getSemantics(find.byKey(const Key('googleSignInButton'))),
      matchesSemantics(
        label: 'Google로 로그인',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('failed logout stays on the calendar and shows a SnackBar',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.apple,
      signOutFailure: const AuthFailure('로그아웃 실패'),
    );
    await _pumpApp(tester, authRepository);

    await _tapLogout(tester);

    expect(authRepository.storedProvider, AuthProviderType.apple);
    expect(find.byKey(const Key('todayContent')), findsOneWidget);
    expect(find.text('로그아웃 실패'), findsOneWidget);
  });

  testWidgets('legacy day route redirects an authenticated user to Today',
      (tester) async {
    final authRepository = _FakeAuthSessionRepository(
      storedProvider: AuthProviderType.google,
    );
    await _pumpApp(tester, authRepository);

    _routerOf(tester).go(AppRoutes.day);
    await tester.pumpAndSettle();

    expect(_routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.today);
    expect(find.byKey(const Key('todayContent')), findsOneWidget);
  });

  testWidgets('bottom navigation switches Today, Week, and Month routes',
      (tester) async {
    await _pumpApp(
      tester,
      _FakeAuthSessionRepository(storedProvider: AuthProviderType.google),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0);

    await tester.tap(find.byKey(const Key('calendarWeekDestination')));
    await tester.pumpAndSettle();
    expect(_routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.week);
    expect(find.textContaining('Week View'), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1);

    await tester.tap(find.byKey(const Key('calendarMonthDestination')));
    await tester.pumpAndSettle();
    expect(_routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.month);
    expect(find.textContaining('Month View'), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2);

    await tester.tap(find.byKey(const Key('calendarTodayDestination')));
    await tester.pumpAndSettle();
    expect(_routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.today);
    expect(find.byKey(const Key('todayContent')), findsOneWidget);
  });

  testWidgets('overflow contains only management actions and logout',
      (tester) async {
    await _pumpApp(
      tester,
      _FakeAuthSessionRepository(storedProvider: AuthProviderType.google),
    );

    await tester.tap(find.byKey(const Key('calendarMoreMenu')));
    await tester.pumpAndSettle();

    expect(find.text('루틴 관리'), findsOneWidget);
    expect(find.text('카테고리 관리'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('일 보기'), findsNothing);
    expect(find.text('주 보기'), findsNothing);
    expect(find.text('월 보기'), findsNothing);
  });

  for (final action in const {
    'routineManagementAction': '루틴 관리 화면은 다음 작업에서 제공됩니다.',
    'categoryManagementAction': '카테고리 관리 화면은 다음 작업에서 제공됩니다.',
    'settingsAction': '설정 화면은 다음 작업에서 제공됩니다.',
  }.entries) {
    testWidgets('${action.key} stays on the route and shows a placeholder',
        (tester) async {
      await _pumpApp(
        tester,
        _FakeAuthSessionRepository(storedProvider: AuthProviderType.google),
      );

      await tester.tap(find.byKey(const Key('calendarMoreMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(action.key)));
      await tester.pump();

      expect(_routerOf(tester).routeInformationProvider.value.uri.path,
          AppRoutes.today);
      expect(find.text(action.value), findsOneWidget);
    });
  }

  for (final action in const {
    'addEventAction': '일정 추가 화면은 다음 작업에서 제공됩니다.',
    'addTodoAction': '투두 추가 화면은 다음 작업에서 제공됩니다.',
  }.entries) {
    testWidgets('FAB ${action.key} closes the sheet and keeps the route',
        (tester) async {
      await _pumpApp(
        tester,
        _FakeAuthSessionRepository(storedProvider: AuthProviderType.google),
      );

      await tester.tap(find.byKey(const Key('calendarAddButton')));
      await tester.pumpAndSettle();

      expect(find.text('일정 추가'), findsOneWidget);
      expect(find.text('투두 추가'), findsOneWidget);
      expect(find.text('루틴 관리'), findsNothing);

      await tester.tap(find.byKey(Key(action.key)));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(_routerOf(tester).routeInformationProvider.value.uri.path,
          AppRoutes.today);
      expect(find.text(action.value), findsOneWidget);
    });
  }

  for (final size in const [Size(390, 844), Size(1200, 900)]) {
    testWidgets('calendar shell fits ${size.width.toInt()}px', (tester) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(() {
        tester.view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
      });

      await _pumpApp(
        tester,
        _FakeAuthSessionRepository(storedProvider: AuthProviderType.google),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('NAE MO'), findsOneWidget);
      expect(find.byKey(const Key('calendarAddButton')), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  }

  testWidgets('login remains usable with large system text', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view
        ..resetPhysicalSize()
        ..resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await _pumpApp(tester, _FakeAuthSessionRepository());

    expect(tester.takeException(), isNull);
    expect(find.text('NAE MO'), findsOneWidget);
    expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    expect(find.byKey(const Key('appleSignInButton')), findsOneWidget);
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
        const AuthenticatedSession(
          uid: 'google-user',
          provider: AuthProviderType.google,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('todayContent')), findsOneWidget);
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
        getTodayOverviewUseCaseProvider.overrideWithValue(
          _EmptyTodayOverviewUseCase(),
        ),
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
  final bool cancelSignIn;

  int signInCalls = 0;

  _FakeAuthSessionRepository({
    this.storedProvider,
    this.restoreCompleter,
    this.signInCompleter,
    this.signInFailure,
    this.signOutFailure,
    this.cancelSignIn = false,
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
        ? cancelSignIn
            ? success<AuthSession>(const UnauthenticatedSession())
            : signInFailure == null
                ? success<AuthSession>(AuthenticatedSession(
                    uid: '${provider.name}-user',
                    provider: provider,
                  ))
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
        : AuthenticatedSession(
            uid: '${provider.name}-user',
            provider: provider,
          );
  }
}

class _EmptyTaskRepository implements TaskRepository {
  @override
  Future<Result<domain.Task>> getTaskById(String id) async =>
      fail(const CacheFailure('Task not found'));

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
  Future<Result<List<domain.Task>>> getTasksForTodayOverview(
    DateTime selectedDate,
  ) async =>
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

class _EmptyTodayOverviewUseCase extends GetTodayOverviewUseCase {
  _EmptyTodayOverviewUseCase()
      : super(_EmptyTaskRepository(), _UnusedCategoryRepository());

  @override
  Future<Result<TodayOverview>> call(DateTime selectedDate) async {
    final local = selectedDate.toLocal();
    return success(
      TodayOverview(
        date: DateTime(local.year, local.month, local.day),
        overdueTodos: const [],
        allDayEvents: const [],
        timelineItems: const [],
        untimedTodos: const [],
        completedTodos: const [],
      ),
    );
  }
}

class _UnusedCategoryRepository extends Fake implements CategoryRepository {}

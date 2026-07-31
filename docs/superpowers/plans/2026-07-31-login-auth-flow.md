# NAE MO Login and Auth Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist a temporary Google or Apple provider session, restore it before routing, send signed-in users to the existing day calendar, and let them sign out from the calendar AppBar.

**Architecture:** Add an `auth` feature that follows the repository's View → ViewModel → UseCase → Repository → DataSource boundaries. `SharedPreferencesAsync` stores only `google` or `apple`; an `AsyncNotifier` owns session state; one GoRouter redirect protects `/login` and calendar routes. The restore screen remains a neutral progress indicator so the branded splash can be delivered in its own PR.

**Tech Stack:** Flutter 3.24.5, Dart 3.5.4, Riverpod 2.6, GoRouter 14.8, shared_preferences 2.5, flutter_svg 2.0, flutter_test.

---

## Delivery rules

- Work only on `codex/login-auth-flow`, based on `origin/main`; do not merge product-spec PR #3.
- Keep each commit to exactly one changed, added, or deleted file.
- Follow red → green → refactor for behavior. A red test-file commit is allowed so the one-file commit rule remains intact.
- Do not add OAuth SDKs, tokens, profile data, or a branded splash.
- Do not clean up pre-existing Riverpod or Drift deprecations in this PR.
- Use official brand assets without redrawing or recoloring either logo.
- Before each commit, confirm scope with `git diff --name-only --cached` and require exactly one path.

## Task 1: Add the auth domain model

**Files:**

- Create: `lib/features/auth/domain/entities/auth_session.dart`

- [ ] Add the only two supported providers and non-null session variants. Keep parsing next to the enum so an unsupported persisted string deterministically becomes no session.

```dart
enum AuthProviderType {
  google,
  apple;

  static AuthProviderType? fromStorageValue(String? value) => switch (value) {
        'google' => AuthProviderType.google,
        'apple' => AuthProviderType.apple,
        _ => null,
      };
}

sealed class AuthSession {
  const AuthSession();
}

final class UnauthenticatedSession extends AuthSession {
  const UnauthenticatedSession();
}

final class AuthenticatedSession extends AuthSession {
  final AuthProviderType provider;
  const AuthenticatedSession(this.provider);
}
```

- [ ] Run `dart format lib/features/auth/domain/entities/auth_session.dart`.
- [ ] Commit only this file: `git commit -m "feat: define auth session model"`.

## Task 2: Define the repository contract and use cases

**Files:**

- Create: `lib/features/auth/domain/repositories/auth_session_repository.dart`
- Create: `lib/features/auth/domain/usecases/auth_session_use_cases.dart`

- [ ] Define a repository whose three operations always return a non-null `AuthSession`, avoiding the repository's nullable-success limitation in `Result<T>`.

```dart
abstract interface class AuthSessionRepository {
  Future<Result<AuthSession>> restoreSession();
  Future<Result<AuthSession>> signIn(AuthProviderType provider);
  Future<Result<AuthSession>> signOut();
}
```

- [ ] Format and commit only the repository file: `git commit -m "feat: define auth session repository"`.
- [ ] Add three callable use cases that delegate exactly once to the contract.

```dart
class RestoreAuthSessionUseCase {
  final AuthSessionRepository _repository;
  const RestoreAuthSessionUseCase(this._repository);
  Future<Result<AuthSession>> call() => _repository.restoreSession();
}

class SignInUseCase {
  final AuthSessionRepository _repository;
  const SignInUseCase(this._repository);
  Future<Result<AuthSession>> call(AuthProviderType provider) =>
      _repository.signIn(provider);
}

class SignOutUseCase {
  final AuthSessionRepository _repository;
  const SignOutUseCase(this._repository);
  Future<Result<AuthSession>> call() => _repository.signOut();
}
```

- [ ] Format and commit only the use-case file: `git commit -m "feat: add auth session use cases"`.

## Task 3: Specify repository behavior with failing tests

**Files:**

- Create: `test/features/auth/data/repositories/auth_session_repository_impl_test.dart`

- [ ] Add a controllable fake `AuthSessionLocalDataSource` and tests for:

  - no saved provider → `UnauthenticatedSession`
  - Google/Apple provider → `AuthenticatedSession`
  - sign-in writes the selected provider before reporting success
  - sign-out clears storage before reporting unauthenticated
  - read/write/clear `CacheException` → `CacheFailure`

- [ ] Run the focused test and confirm red because DataSource/implementation files do not yet exist:

```powershell
flutter test --no-pub test/features/auth/data/repositories/auth_session_repository_impl_test.dart
```

Expected: compile failure naming the missing auth DataSource or repository implementation.

- [ ] Commit only the red test file: `git commit -m "test: specify auth session repository"`.

## Task 4: Implement local persistence

**Files:**

- Create: `lib/features/auth/data/datasources/auth_session_local_data_source.dart`
- Create: `lib/features/auth/data/datasources/auth_session_local_data_source_impl.dart`

- [ ] Define the narrow DataSource contract.

```dart
abstract interface class AuthSessionLocalDataSource {
  Future<AuthProviderType?> readProvider();
  Future<void> writeProvider(AuthProviderType provider);
  Future<void> clearProvider();
}
```

- [ ] Format and commit only the contract: `git commit -m "feat: define auth session data source"`.
- [ ] Implement it with `SharedPreferencesAsync`, key `auth.provider`, enum `name`, and `CacheException` wrapping for plugin failures.

```dart
class AuthSessionLocalDataSourceImpl implements AuthSessionLocalDataSource {
  static const providerKey = 'auth.provider';
  final SharedPreferencesAsync _preferences;

  const AuthSessionLocalDataSourceImpl(this._preferences);

  @override
  Future<AuthProviderType?> readProvider() async {
    try {
      final value = await _preferences.getString(providerKey);
      return AuthProviderType.fromStorageValue(value);
    } on Object catch (error) {
      throw CacheException('로그인 정보를 불러오지 못했습니다: $error');
    }
  }

  @override
  Future<void> writeProvider(AuthProviderType provider) async {
    try {
      await _preferences.setString(providerKey, provider.name);
    } on Object catch (error) {
      throw CacheException('로그인 정보를 저장하지 못했습니다: $error');
    }
  }

  @override
  Future<void> clearProvider() async {
    try {
      await _preferences.remove(providerKey);
    } on Object catch (error) {
      throw CacheException('로그아웃 정보를 저장하지 못했습니다: $error');
    }
  }
}
```

- [ ] Format and commit only the implementation: `git commit -m "feat: persist auth provider locally"`.

## Task 5: Implement the repository and make its tests green

**Files:**

- Create: `lib/features/auth/data/repositories/auth_session_repository_impl.dart`

- [ ] Map missing/unknown values to `UnauthenticatedSession`, saved values to `AuthenticatedSession`, and every `CacheException` to `CacheFailure`. Never report a state change before the DataSource call succeeds.

```dart
class AuthSessionRepositoryImpl implements AuthSessionRepository {
  final AuthSessionLocalDataSource _localDataSource;
  const AuthSessionRepositoryImpl(this._localDataSource);

  @override
  Future<Result<AuthSession>> restoreSession() async => _guard(() async {
        final provider = await _localDataSource.readProvider();
        return provider == null
            ? const UnauthenticatedSession()
            : AuthenticatedSession(provider);
      });

  @override
  Future<Result<AuthSession>> signIn(AuthProviderType provider) async =>
      _guard(() async {
        await _localDataSource.writeProvider(provider);
        return AuthenticatedSession(provider);
      });

  @override
  Future<Result<AuthSession>> signOut() async => _guard(() async {
        await _localDataSource.clearProvider();
        return const UnauthenticatedSession();
      });
}
```

Add a private `_guard` that returns `fail(CacheFailure(error.message))` for `CacheException` and a stable generic cache failure for unexpected storage errors.

- [ ] Run the focused test. Expected: all repository tests pass.
- [ ] Format and commit only the implementation: `git commit -m "feat: implement auth session repository"`.

## Task 6: Wire auth dependencies

**Files:**

- Create: `lib/features/auth/auth_providers.dart`

- [ ] Use manual, non-generated Riverpod providers for `SharedPreferencesAsync`, the DataSource, repository, and three use cases. Keep `authSessionRepositoryProvider` public so tests can override the full feature boundary.

```dart
final sharedPreferencesAsyncProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

final authSessionRepositoryProvider = Provider<AuthSessionRepository>((ref) {
  final preferences = ref.watch(sharedPreferencesAsyncProvider);
  final dataSource = AuthSessionLocalDataSourceImpl(preferences);
  return AuthSessionRepositoryImpl(dataSource);
});
```

- [ ] Format and commit only this file: `git commit -m "feat: wire auth dependencies"`.

## Task 7: Specify and implement auth presentation state

**Files:**

- Create: `test/features/auth/presentation/viewmodels/auth_view_model_test.dart`
- Create: `lib/features/auth/presentation/states/auth_state.dart`
- Create: `lib/features/auth/presentation/viewmodels/auth_view_model.dart`

- [ ] In the test, override `authSessionRepositoryProvider` with a deferred fake and verify:

  - provider starts in `AsyncLoading`
  - restore resolves to unauthenticated/authenticated
  - Google and Apple sign-in set `isSubmitting` and `pendingProvider`, ignore duplicate taps, then replace the session
  - sign-in failure keeps the old session and exposes a Korean error
  - sign-out success becomes unauthenticated
  - sign-out failure keeps authenticated session and exposes an error

- [ ] Run the focused test and confirm red because state/ViewModel are absent.
- [ ] Commit only the red test file: `git commit -m "test: specify auth state transitions"`.
- [ ] Add immutable `AuthState` with `session`, `isSubmitting`, nullable `pendingProvider`, nullable `errorMessage`, and a `copyWith` capable of explicitly clearing both nullable fields.
- [ ] Format and commit only the state file: `git commit -m "feat: define auth presentation state"`.
- [ ] Implement `AsyncNotifier<AuthState>` and its manual provider. `build()` catches all failures and always resolves to an unauthenticated state with a recoverable message rather than leaving the app on the loader.

```dart
final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);

class AuthViewModel extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final result = await ref.read(restoreAuthSessionUseCaseProvider)();
    return result.fold(
      onSuccess: (session) => AuthState(session: session),
      onFailure: (failure) => AuthState(
        session: const UnauthenticatedSession(),
        errorMessage: failure.message,
      ),
    );
  }
}
```

`signIn` and `signOut` must use the inner submitting state, await their UseCases, preserve the previous session on failure, clear pending state, and ignore duplicate requests.

- [ ] Run the focused test. Expected: all ViewModel tests pass.
- [ ] Format and commit only the ViewModel: `git commit -m "feat: manage auth session state"`.

## Task 8: Add official brand assets

**Files:**

- Create: `assets/icons/google_g.svg`
- Create: `assets/images/apple_continue_black_ko.png`
- Create: `assets/images/apple_continue_white_ko.png`

- [ ] Copy the unmodified Google `G` SVG from Google's official Sign-in branding asset package: `https://developers.google.com/static/identity/images/signin-assets.zip`.
- [ ] Commit only it: `git commit -m "assets: add official Google sign-in mark"`.
- [ ] Download Apple's official Korean Continue button images from its REST asset endpoint at 3× scale, 343×52 logical points, radius 8:

```text
https://appleid.cdn-apple.com/appleid/button?height=52&width=343&color=black&border=false&type=continue&border_radius=8&scale=3&locale=ko_KR
https://appleid.cdn-apple.com/appleid/button?height=52&width=343&color=white&border=true&type=continue&border_radius=8&scale=3&locale=ko_KR
```

- [ ] Inspect both PNGs to confirm Korean text, correct contrast, and no clipping.
- [ ] Commit the black image alone: `git commit -m "assets: add official Apple dark sign-in button"`.
- [ ] Commit the white image alone: `git commit -m "assets: add official Apple light sign-in button"`.
- [ ] Run `flutter analyze --no-pub` and confirm the prior missing `assets/images/` and `assets/icons/` issues disappear.

## Task 9: Build the neutral restore page and branded login page

**Files:**

- Create: `lib/features/auth/presentation/pages/auth_loading_page.dart`
- Create: `lib/features/auth/presentation/pages/login_page.dart`

- [ ] Add a `Scaffold` with a centered `CircularProgressIndicator` and semantic label `로그인 정보 확인 중` only. Do not add the future splash branding here.
- [ ] Commit only it: `git commit -m "feat: add auth restore loading page"`.
- [ ] Build a `ConsumerWidget` login page with:

  - SafeArea and centered single column
  - max content width 343
  - exact wordmark `NAE MO`
  - short Korean explanation
  - equal-width Google and Apple buttons
  - Google official `G`, official light/dark colors and border, localized Continue label
  - Apple official full-button PNG selected from current brightness
  - `Semantics(button: true, label: ...)` and keyboard/touch InkWell behavior
  - both buttons disabled during a request
  - progress overlay only on the selected button
  - error text next to the buttons with `liveRegion: true`

- [ ] Do not navigate from the page; call `AuthViewModel.signIn` and let router state perform the transition.
- [ ] Format and commit only the page: `git commit -m "feat: build branded login page"`.

## Task 10: Protect routes with restored session state

**Files:**

- Modify: `lib/core/router/app_router.dart`
- Delete: `lib/core/router/app_router.g.dart`

- [ ] Replace the generated router provider with a manual `Provider<GoRouter>` and a small private `ChangeNotifier` bridge driven by `ref.listen(authViewModelProvider, ...)`.
- [ ] Add `AppRoutes.bootstrap = '/bootstrap'` and `AppRoutes.login = '/login'`; set initial location to bootstrap.
- [ ] Add top-level routes for `AuthLoadingPage` and `LoginPage`, retaining the existing calendar `ShellRoute` unchanged.
- [ ] Implement one pure redirect function with this truth table:

| Auth state | Requested location | Redirect |
| --- | --- | --- |
| restoring | any non-bootstrap route | `/bootstrap` |
| restoring | `/bootstrap` | none |
| unauthenticated | `/login` | none |
| unauthenticated | anything else | `/login` |
| authenticated | `/login` or `/bootstrap` | `/calendar/day` |
| authenticated | calendar route | none |

- [ ] Format and commit only `app_router.dart`: `git commit -m "feat: guard routes by auth session"`.
- [ ] Delete only the obsolete generated file and commit: `git commit -m "chore: remove generated router provider"`.
- [ ] Run `flutter analyze --no-pub`. Expected: no new analyzer findings; `app_router.g.dart` is no longer referenced.

## Task 11: Add logout to the existing calendar shell

**Files:**

- Modify: `lib/features/calendar/presentation/pages/calendar_shell_page.dart`

- [ ] Add an AppBar overflow menu after the existing view switcher. Its `로그아웃` item calls `AuthViewModel.signOut`.
- [ ] Disable or ignore duplicate selections while `isSubmitting` is true.
- [ ] Use `ref.listen` to display a SnackBar only when a new logout failure appears. Successful logout navigation remains router-owned.
- [ ] Keep all date navigation and day/week/month switching behavior unchanged.
- [ ] Format and commit only this file: `git commit -m "feat: add calendar logout action"`.

## Task 12: Cover the complete app flow

**Files:**

- Modify: `test/widget_test.dart`

- [ ] Call `initializeDateFormatting('ko', null)` in `setUpAll`.
- [ ] Replace the smoke-only test with an in-memory repository widget harness and cover:

  - no session → `NAE MO` login page
  - direct calendar path while signed out → login page
  - Google login → existing day page
  - Apple login → existing day page
  - persisted provider and app recreation → day page without login flash
  - authenticated `/login` → day page
  - overflow logout → login page and cleared provider
  - failed sign-in → stays on login and shows error
  - failed sign-out → stays on calendar and shows SnackBar
  - buttons expose semantic labels and lock during a deferred request

- [ ] Use `pump()` then controlled completion/pump cycles; avoid unbounded `pumpAndSettle()` while a deferred restore is intentionally pending.
- [ ] Run `flutter test --no-pub test/widget_test.dart`. Expected: all flow tests pass.
- [ ] Format and commit only this file: `git commit -m "test: cover login persistence and logout flow"`.

## Task 13: Full verification and regression comparison

**Files:** none unless a failure identifies an in-scope defect.

- [ ] Run format verification:

```powershell
dart format --output=none --set-exit-if-changed lib test
```

Expected: exit 0, no changed files.

- [ ] Run the full suite:

```powershell
flutter test --no-pub
```

Expected: exit 0, all tests pass.

- [ ] Run analysis:

```powershell
flutter analyze --no-pub
```

Expected: no errors and no newly introduced warnings. Pre-existing generated Riverpod/Drift deprecations may keep the command non-zero; compare to the recorded `origin/main` baseline of 21 issues and require the count not to increase. The two missing asset-directory findings must be gone.

- [ ] Check one-file commit discipline:

```powershell
git log --format="%h %s" --name-only origin/main..HEAD
git status --short
```

Expected: every implementation commit lists exactly one path; working tree clean.

- [ ] Review every changed production file against `docs/superpowers/specs/2026-07-31-login-auth-flow-design.md`; verify there are no tokens, fake user records, OAuth dependencies, splash branding, TODOs, or placeholder error handling.

## Task 14: Run the app and collect review evidence

**Files:**

- Create after PR number is known: `docs/design/evidence/pr-<number>-login-auth/login-light.png`
- Create after PR number is known: `docs/design/evidence/pr-<number>-login-auth/login-dark.png`
- Create after PR number is known: `docs/design/evidence/pr-<number>-login-auth/calendar-after-login.png`

- [ ] Start a supported target, prefer Chrome for reproducible PR screenshots: `flutter run -d chrome`.
- [ ] Verify manually: initial restore does not flash login, sign-in reaches `/calendar/day`, browser refresh restores that session, logout returns to login, browser refresh remains logged out.
- [ ] Capture real rendered screenshots at a consistent mobile viewport in light and dark themes, plus the day screen after login.
- [ ] Commit each PNG separately, one commit per file, using `docs: add ... evidence` messages.
- [ ] Re-run `flutter test --no-pub` after evidence commits to ensure no source changed during capture.

## Task 15: Push and open a reviewable PR

- [ ] Run `git diff --check origin/main...HEAD` and require no whitespace errors.
- [ ] Push `codex/login-auth-flow` without touching PR #3.
- [ ] Open a ready-for-review PR to `main`. The body must include:

  - temporary provider-session scope and explicit OAuth exclusions
  - restore/login/logout flow summary
  - architecture boundaries
  - manual and automated verification results
  - analyzer baseline comparison
  - embedded light, dark, and post-login screenshots
  - follow-up links/notes for separate splash and real OAuth PRs

- [ ] If the final production/test diff is too large for one coherent review, stop before PR creation and split at the natural boundary: PR A for auth persistence/state/routing, PR B for branded login UI/logout. Do not split merely by layer if that leaves either PR unusable.

# Today Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the legacy split Day placeholder with the approved mobile-first Today page, preserve authentication and legacy route compatibility, and provide tested mobile/Web visual evidence.

**Architecture:** `TodayViewModel` is the single presentation state owner. It watches the shared selected date, loads the merged `TodayOverview`, owns the two collapsed sections, and performs optimistic todo completion with rollback. `TodayPage` composes focused section widgets, while `CalendarShellPage` owns global navigation, management actions, add actions, and logout.

**Tech Stack:** Flutter 3.24.5, Dart 3.5.4, Material 3, Riverpod 2.6.1, GoRouter 14.8.1, `flutter_test`, Chrome.

**Design:** `docs/superpowers/specs/2026-07-31-today-redesign-design.md`

**Visual reference:** `docs/design/reference/today-date-canvas.png`

---

## File responsibilities

- `lib/features/calendar/presentation/states/today_state.dart`: immutable loaded Today state, expansion flags, pending todo IDs.
- `lib/features/calendar/presentation/viewmodels/today_view_model.dart`: selected-date loading, retry, collapse state, optimistic completion and rollback.
- `lib/features/calendar/presentation/widgets/today_date_header.dart`: year/month heading, selected day, previous/today/next controls, centered seven-day strip.
- `lib/features/calendar/presentation/widgets/today_overdue_section.dart`: collapsed overdue summary and expanded original-date todo rows.
- `lib/features/calendar/presentation/widgets/today_all_day_section.dart`: optional all-day event cards.
- `lib/features/calendar/presentation/widgets/today_timeline_section.dart`: compact vertical timeline for timed events and todos.
- `lib/features/calendar/presentation/widgets/today_todo_section.dart`: untimed and completed todo lists.
- `lib/features/calendar/presentation/pages/today_page.dart`: loading/error/content composition and mutation Snackbar.
- `lib/features/calendar/presentation/pages/calendar_shell_page.dart`: global menu, add sheet, bottom navigation, logout.
- `lib/core/router/app_router.dart`: `/calendar/today`, legacy `/calendar/day` redirect, authenticated default route.
- `test/features/calendar/presentation/`: ViewModel and focused widget behavior.
- `test/widget_test.dart`: authentication, shell, route, menu, and responsive regressions.
- `test/visual/today_fixture_app.dart`: deterministic verification-only app that renders the real shell and Today page without seeding production data.
- `docs/design/evidence/pr-<number>-today-page/`: committed browser screenshots.

Every commit changes exactly one path. RED tests are committed before the production path that makes them pass. Generated paths and deleted legacy paths are committed individually.

---

### Task 1: Define the Today presentation state

**Files:**

- Create: `test/features/calendar/presentation/states/today_state_test.dart`
- Create: `lib/features/calendar/presentation/states/today_state.dart`

- [ ] **Step 1: Write the failing state test**

Create a fixture `TodayOverview` and assert that the initial state is collapsed, has no pending IDs, and `copyWith` replaces only requested fields:

```dart
final state = TodayState(overview: overview);
expect(state.isOverdueExpanded, isFalse);
expect(state.isCompletedExpanded, isFalse);
expect(state.pendingTodoIds, isEmpty);

final changed = state.copyWith(
  isOverdueExpanded: true,
  pendingTodoIds: const {'todo'},
);
expect(changed.overview, same(overview));
expect(changed.isOverdueExpanded, isTrue);
expect(changed.isCompletedExpanded, isFalse);
expect(changed.pendingTodoIds, const {'todo'});
```

- [ ] **Step 2: Run RED and commit only the test**

Run: `flutter test --no-pub test/features/calendar/presentation/states/today_state_test.dart`

Expected: compilation fails because `TodayState` does not exist.

Commit only the test with `test: define Today presentation state`.

- [ ] **Step 3: Implement the immutable state**

Implement:

```dart
class TodayState {
  final TodayOverview overview;
  final bool isOverdueExpanded;
  final bool isCompletedExpanded;
  final Set<String> pendingTodoIds;

  const TodayState({
    required this.overview,
    this.isOverdueExpanded = false,
    this.isCompletedExpanded = false,
    this.pendingTodoIds = const {},
  });

  TodayState copyWith({
    TodayOverview? overview,
    bool? isOverdueExpanded,
    bool? isCompletedExpanded,
    Set<String>? pendingTodoIds,
  }) => TodayState(
        overview: overview ?? this.overview,
        isOverdueExpanded:
            isOverdueExpanded ?? this.isOverdueExpanded,
        isCompletedExpanded:
            isCompletedExpanded ?? this.isCompletedExpanded,
        pendingTodoIds: Set.unmodifiable(
          pendingTodoIds ?? this.pendingTodoIds,
        ),
      );
}
```

Commit only `today_state.dart` with `feat: add Today presentation state`.

- [ ] **Step 4: Run GREEN**

Run the focused state test. Expected: pass.

### Task 2: Load Today and update todos optimistically

**Files:**

- Create: `test/features/calendar/presentation/viewmodels/today_view_model_test.dart`
- Create: `lib/features/calendar/presentation/viewmodels/today_view_model.dart`
- Generate: `lib/features/calendar/presentation/viewmodels/today_view_model.g.dart`

- [ ] **Step 1: Write the failing ViewModel tests**

Override `getTodayOverviewUseCaseProvider` and `toggleCompleteUseCaseProvider` with controllable fakes and cover:

```dart
test('loads the selected date with both sections collapsed', () async {
  final harness = _Harness(initialOverview: _overview(DateTime(2026, 8, 3)));
  final loaded = await harness.container.read(todayViewModelProvider.future);
  expect(loaded.overview.date, DateTime(2026, 8, 3));
  expect(loaded.isOverdueExpanded, isFalse);
  expect(loaded.isCompletedExpanded, isFalse);
});

test('date changes reload and reset both collapsed sections', () async {
  final harness = _Harness(initialOverview: _overview(DateTime(2026, 8, 3)));
  await harness.container.read(todayViewModelProvider.future);
  harness.container.read(todayViewModelProvider.notifier)
    ..toggleOverdueSection()
    ..toggleCompletedSection();
  harness.container.read(selectedDateProvider.notifier).select(DateTime(2026, 8, 4));
  final loaded = await harness.container.read(todayViewModelProvider.future);
  expect(loaded.overview.date, DateTime(2026, 8, 4));
  expect(loaded.isOverdueExpanded, isFalse);
  expect(loaded.isCompletedExpanded, isFalse);
});

test('failed completion restores the previous state and returns failure', () async {
  const failure = CacheFailure('완료 상태를 저장하지 못했습니다.');
  final harness = _Harness(
    initialOverview: _overviewWithUntimedTodo(),
    toggleFailure: failure,
  );
  final before = await harness.container.read(todayViewModelProvider.future);
  final returned = await harness.container
      .read(todayViewModelProvider.notifier)
      .toggleTodo('untimed');
  final after = harness.container.read(todayViewModelProvider).requireValue;
  expect(returned, failure);
  expect(after.overview.untimedTodos.single.task.id, 'untimed');
  expect(after.overview.completedTodos, isEmpty);
  expect(after.pendingTodoIds, isEmpty);
  expect(before.overview.untimedTodos.single.task.id, 'untimed');
});
```

Add equally explicit tests named `retry reads the current selected date again`,
`todo completion moves immediately before persistence finishes`, `successful
completion keeps the optimistic result`, and `duplicate completion taps are
ignored while the todo is pending`. The optimistic fixtures must cover an
untimed selected-date todo, a timed selected-date todo, an overdue todo, and a
completed todo. Verify each item moves to or from the correct exclusive list.

- [ ] **Step 2: Run RED and commit only the test**

Run: `flutter test --no-pub test/features/calendar/presentation/viewmodels/today_view_model_test.dart`

Expected: compilation fails because `todayViewModelProvider` does not exist.

Commit only the test with `test: define Today view model behavior`.

- [ ] **Step 3: Implement the ViewModel**

Use an `@riverpod` `AsyncNotifier<TodayState>`:

```dart
@riverpod
class TodayViewModel extends _$TodayViewModel {
  @override
  Future<TodayState> build() async {
    final selectedDate = ref.watch(selectedDateProvider);
    final result = await ref.read(getTodayOverviewUseCaseProvider)(selectedDate);
    return result.fold(
      onSuccess: (overview) => TodayState(overview: overview),
      onFailure: (failure) => throw failure,
    );
  }

  void retry() => ref.invalidateSelf();

  void toggleOverdueSection() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(isOverdueExpanded: !current.isOverdueExpanded),
    );
  }

  void toggleCompletedSection() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(isCompletedExpanded: !current.isCompletedExpanded),
    );
  }

  Future<Failure?> toggleTodo(String taskId) async {
    final previous = state.valueOrNull;
    if (previous == null || previous.pendingTodoIds.contains(taskId)) {
      return null;
    }
    final optimistic = _toggleCompletion(previous, taskId);
    state = AsyncData(optimistic.copyWith(
      pendingTodoIds: {...optimistic.pendingTodoIds, taskId},
    ));
    final result = await ref.read(toggleCompleteUseCaseProvider)(taskId);
    final failure = result.failure;
    if (failure != null) {
      if (state.valueOrNull?.overview.date == previous.overview.date) {
        state = AsyncData(previous);
      }
      return failure;
    }
    final current = state.valueOrNull;
    if (current != null && current.overview.date == previous.overview.date) {
      state = AsyncData(current.copyWith(
        pendingTodoIds: {...current.pendingTodoIds}..remove(taskId),
      ));
    }
    return null;
  }
}
```

`toggleTodo` must snapshot the loaded state, move the entry immediately, mark the ID pending, await `ToggleCompleteUseCase`, retain the optimistic overview on success, and restore the snapshot on failure only if the user is still viewing the same date. It returns the failure for the page to display. Use private helpers that clone `Task` with the inverse completion value and rebuild unmodifiable Today lists without duplicates.

Commit only `today_view_model.dart` with `feat: manage Today interactions`.

- [ ] **Step 4: Generate the provider and commit it alone**

Run:

```powershell
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/features/calendar/presentation/viewmodels/today_view_model.g.dart
```

Commit only `today_view_model.g.dart` with `build: generate Today view model provider`.

- [ ] **Step 5: Run GREEN**

Run the focused ViewModel test. Expected: all cases pass.

### Task 3: Build the date header

**Files:**

- Create: `test/features/calendar/presentation/widgets/today_date_header_test.dart`
- Create: `lib/features/calendar/presentation/widgets/today_date_header.dart`

- [ ] **Step 1: Write the failing widget tests**

Pump `TodayDateHeader` at `DateTime(2026, 7, 29)` and assert:

- `2026년 7월`, `29일 수요일`, and seven dates from 26 through 1 are visible;
- selected date has key `todayDate-2026-07-29` and selected semantics;
- previous, today, and next controls call their callbacks;
- tapping `31` passes `DateTime(2026, 7, 31)`;
- 390px width and text scale 2 do not overflow.

- [ ] **Step 2: Run RED and commit only the test**

Expected: compilation fails because `TodayDateHeader` does not exist. Commit with `test: define Today date header behavior`.

- [ ] **Step 3: Implement the header**

Build a focused stateless widget with this contract:

```dart
class TodayDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onToday;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;
}
```

Normalize dates locally. Create the strip with `List.generate(7, (index) => selectedDate.add(Duration(days: index - 3)))`. Use Korean `DateFormat`, minimum 48px tap targets, a filled selected date capsule, and keys `todayPreviousDate`, `todayGoToToday`, `todayNextDate`, and `todayDate-yyyy-MM-dd`.

Commit only `today_date_header.dart` with `feat: add Today date header`.

- [ ] **Step 4: Run GREEN**

Run the focused header test. Expected: pass with no overflow exception.

### Task 4: Build the Today overview sections

**Files:**

- Create: `test/features/calendar/presentation/widgets/today_sections_test.dart`
- Create: `lib/features/calendar/presentation/widgets/today_overdue_section.dart`
- Create: `lib/features/calendar/presentation/widgets/today_all_day_section.dart`
- Create: `lib/features/calendar/presentation/widgets/today_timeline_section.dart`
- Create: `lib/features/calendar/presentation/widgets/today_todo_section.dart`

- [ ] **Step 1: Write the failing section tests**

Create deterministic `TodayEntry` fixtures and verify:

- overdue is collapsed by default, shows count and oldest date, and reveals original dates when expanded;
- an empty all-day list renders no all-day section;
- all-day cards have no checkbox and use category color;
- timeline shows bold start time, secondary end time, event without checkbox, and timed todo with checkbox;
- untimed todos show checkbox/title/category;
- completed todos stay hidden while collapsed and show checked, struck-through rows when expanded;
- pending todo IDs disable only the matching checkbox;
- callbacks receive the exact task ID.

- [ ] **Step 2: Run RED and commit only the test**

Expected: compilation fails because section widgets do not exist. Commit with `test: define Today section behavior`.

- [ ] **Step 3: Implement overdue and commit the path alone**

Create `TodayOverdueSection` with `entries`, `isExpanded`, `pendingTodoIds`, `onToggleExpanded`, and `onToggleTodo`. Omit the section when empty. The collapsed summary includes count and oldest `M월 d일`; the expanded rows show each original date and title.

Commit with `feat: add overdue todo tray`.

- [ ] **Step 4: Implement all-day events and commit the path alone**

Create `TodayAllDaySection(entries:)`. Omit it when empty. Render one-line tinted cards with a category accent, title, optional category name, and `종일`; never render a checkbox.

Commit with `feat: add all-day event section`.

- [ ] **Step 5: Implement the compact timeline and commit the path alone**

Create `TodayTimelineSection` with entries, pending IDs, and todo callback. Always render the `일정` heading; render a short `시간이 정해진 일정이 없어요.` empty message when empty. Each row has a fixed time column, vertical guide, and colored card. Only todo entries receive a checkbox.

Commit with `feat: add compact Today timeline`.

- [ ] **Step 6: Implement todo lists and commit the path alone**

Create reusable `TodayTodoSection` parameters for title, entries, pending IDs, completion presentation, optional collapsed state, expand callback, and todo callback. Untimed empty state says `시간이 정해지지 않은 할 일이 없어요.`. Completed rows use a checked checkbox and line-through title.

Commit with `feat: add Today todo sections`.

- [ ] **Step 7: Run GREEN**

Run the focused section test. Expected: pass.

### Task 5: Compose the Today page

**Files:**

- Create: `test/features/calendar/presentation/pages/today_page_test.dart`
- Create: `lib/features/calendar/presentation/pages/today_page.dart`

- [ ] **Step 1: Write the failing page tests**

Override `todayViewModelProvider` with controlled AsyncNotifier fixtures and verify:

- loading shows `todayLoadingIndicator`;
- failure shows a full-page Korean message and `todayRetryButton`;
- loaded content orders the six sections exactly as specified;
- selecting previous/today/next/date updates `selectedDateProvider`;
- overdue and completed expansion delegates to the ViewModel;
- failed completion displays the returned failure in a SnackBar;
- content stays centered with a maximum width on 1200px Web;
- 390x844 and 1200x900 layouts have no overflow.

- [ ] **Step 2: Run RED and commit only the test**

Expected: compilation fails because `TodayPage` does not exist. Commit with `test: define Today page states`.

- [ ] **Step 3: Implement the page and commit it alone**

`TodayPage` watches `todayViewModelProvider`. Loading and error states replace the entire body. The data branch uses `SafeArea`, `Align(alignment: topCenter)`, `ConstrainedBox(maxWidth: 720)`, and one `ListView` with bottom padding for the FAB. Compose in this exact order:

```dart
TodayDateHeader(
  selectedDate: loaded.overview.date,
  onPrevious: () => selectedDateNotifier.addDays(-1),
  onToday: selectedDateNotifier.goToToday,
  onNext: () => selectedDateNotifier.addDays(1),
  onSelectDate: selectedDateNotifier.select,
),
TodayOverdueSection(
  entries: loaded.overview.overdueTodos,
  isExpanded: loaded.isOverdueExpanded,
  pendingTodoIds: loaded.pendingTodoIds,
  onToggleExpanded: notifier.toggleOverdueSection,
  onToggleTodo: toggleTodo,
),
TodayAllDaySection(entries: loaded.overview.allDayEvents),
TodayTimelineSection(
  entries: loaded.overview.timelineItems,
  pendingTodoIds: loaded.pendingTodoIds,
  onToggleTodo: toggleTodo,
),
TodayTodoSection(
  title: '시간 미정 할 일',
  entries: loaded.overview.untimedTodos,
  pendingTodoIds: loaded.pendingTodoIds,
  onToggleTodo: toggleTodo,
),
TodayTodoSection(
  title: '완료한 할 일',
  entries: loaded.overview.completedTodos,
  pendingTodoIds: loaded.pendingTodoIds,
  isCompletedPresentation: true,
  isExpanded: loaded.isCompletedExpanded,
  onToggleExpanded: notifier.toggleCompletedSection,
  onToggleTodo: toggleTodo,
),
```

Await `toggleTodo`; if it returns a failure, replace the current SnackBar with `failure.message`.

Commit with `feat: compose Today page`.

- [ ] **Step 4: Run GREEN**

Run the focused page test. Expected: pass.

### Task 6: Replace the global calendar shell

**Files:**

- Modify: `test/widget_test.dart`
- Modify: `lib/features/calendar/presentation/pages/calendar_shell_page.dart`
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: Rewrite shell and route expectations in the app test**

Replace Day/Task Dock assertions with Today behavior and add coverage for:

- authenticated restore and login land at `/calendar/today`;
- `/calendar/day` redirects to `/calendar/today`;
- bottom navigation exposes `오늘`, `주간`, `월간` and switches existing routes;
- menu contains `루틴 관리`, `카테고리 관리`, `설정`, `로그아웃`;
- future-scope menu items keep the route and show a SnackBar;
- FAB sheet contains only `일정 추가` and `투두 추가`, and both show a future-scope SnackBar;
- logout remains functional and a failed logout stays on Today;
- 390x844 and 1200x900 shell layouts do not overflow.

Override the Today use cases so the app test never reads production Drift data.

- [ ] **Step 2: Run RED and commit only `test/widget_test.dart`**

Expected: existing shell lacks Today route, bottom navigation, management menu, and add sheet. Commit with `test: define Today calendar shell`.

- [ ] **Step 3: Implement the shell and commit it alone**

Replace the AppBar date/view switcher with a simple left-aligned `NAE MO` title and the management overflow menu. Add:

```dart
NavigationBar(
  selectedIndex: activeIndex,
  destinations: const [
    NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: '오늘'),
    NavigationDestination(icon: Icon(Icons.view_week_outlined), selectedIcon: Icon(Icons.view_week), label: '주간'),
    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: '월간'),
  ],
)
```

Use a centered FAB with key `calendarAddButton`; its modal sheet contains only Event and Todo actions. Management/add placeholders close their menu or sheet, keep the current route, and show a Korean SnackBar. Preserve the existing auth listener and logout call.

Commit with `feat: add Today calendar shell`.

- [ ] **Step 4: Implement routes and commit `app_router.dart` alone**

Add `AppRoutes.today = '/calendar/today'`, route it to `TodayPage`, retain `AppRoutes.day` only as a redirect, and change authenticated bootstrap/login redirects to Today. Keep Week and Month builders unchanged.

Commit with `feat: route authenticated users to Today`.

- [ ] **Step 5: Run GREEN**

Run `flutter test --no-pub test/widget_test.dart`. Expected: all app flow and shell tests pass.

### Task 7: Remove the retired Day split implementation

**Files:**

- Delete: `lib/features/calendar/presentation/pages/day_view_page.dart`
- Delete: `lib/features/calendar/presentation/states/day_view_state.dart`
- Delete: `lib/features/calendar/presentation/states/day_view_state.freezed.dart`
- Delete: `lib/features/calendar/presentation/states/task_dock_state.dart`
- Delete: `lib/features/calendar/presentation/states/task_dock_state.freezed.dart`
- Delete: `lib/features/calendar/presentation/viewmodels/day_view_viewmodel.dart`
- Delete: `lib/features/calendar/presentation/viewmodels/day_view_viewmodel.g.dart`
- Delete: `lib/features/calendar/presentation/viewmodels/task_dock_viewmodel.dart`
- Delete: `lib/features/calendar/presentation/viewmodels/task_dock_viewmodel.g.dart`

- [ ] **Step 1: Prove no production import remains**

Run:

```powershell
rg -n "DayViewPage|DayViewState|dayViewViewModelProvider|TaskDockState|taskDockViewModelProvider" lib test
```

Expected: only the retired paths themselves, with no live import or route reference.

- [ ] **Step 2: Delete and commit each path separately**

Use one deletion commit per file. Use messages such as `refactor: remove legacy Day page`, `refactor: remove legacy Day state`, and `refactor: remove legacy Task Dock provider`. Never combine deletions in one commit.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test --no-pub`

Expected: all tests pass and no test is skipped.

### Task 8: Add deterministic visual verification

**Files:**

- Create: `test/visual/today_fixture_app.dart`
- Create after PR number is known: `docs/design/evidence/pr-<number>-today-page/today-mobile.png`
- Create after PR number is known: `docs/design/evidence/pr-<number>-today-page/today-web.png`
- Create after PR number is known: `docs/design/evidence/pr-<number>-today-page/today-empty.png`

- [ ] **Step 1: Create the verification-only fixture app**

The fixture app must use the real `App`, router, shell, and Today page. Override auth restoration to return an authenticated session, override Today loading with deterministic categories/events/todos, and override toggle completion with a local success result. A `--dart-define=TODAY_EMPTY=true` switch returns an empty `TodayOverview`. Do not insert fixture rows into Drift.

Commit only `today_fixture_app.dart` with `test: add Today visual fixture`.

- [ ] **Step 2: Verify the fixture builds**

Run:

```powershell
flutter build web --release --no-pub -t test/visual/today_fixture_app.dart
```

Expected: exit 0.

- [ ] **Step 3: Push code and create a draft PR to obtain its number**

Before pushing, run the verification commands from Task 9 and confirm one-path commit history. Push `codex/today-page`, then create a draft PR against `main` with the plan reference and verification summary. Keep the worktree.

- [ ] **Step 4: Capture real Chrome screenshots**

Run the fixture on Chrome and capture:

- populated Today at 390x844;
- populated Today at 1200x900;
- empty Today at 390x844.

Store directly under `docs/design/evidence/pr-<number>-today-page/`. Inspect all three images visually. Confirm the reference hierarchy, readable time labels, one-column layout, bottom navigation, FAB, and no clipping.

- [ ] **Step 5: Commit each PNG separately**

Use one commit per image: `docs: add Today mobile evidence`, `docs: add Today web evidence`, `docs: add Today empty evidence`.

### Task 9: Final verification, review, and PR handoff

**Files:** none unless verification reveals a defect.

- [ ] **Step 1: Format all changed Dart paths**

Run `dart format` only over changed Dart files. Confirm `git diff --check` remains clean.

- [ ] **Step 2: Run fresh full verification**

Run:

```powershell
flutter test --no-pub
flutter analyze --no-pub
flutter build web --release --no-pub
git diff --check origin/main...HEAD
```

Record exact test counts, analyzer warnings/errors, and build status. Compare analyzer output to `origin/main` if pre-existing info diagnostics remain.

- [ ] **Step 3: Verify commit scope**

For every commit after `origin/main`, run `git diff-tree --no-commit-id --name-only -r <sha>` and verify exactly one path. Generated files, deleted files, fixture, and each screenshot count as individual paths.

- [ ] **Step 4: Request spec and code-quality review**

Review the complete `origin/main...HEAD` diff against the design. Fix every Critical or Important issue with one-path commits, then rerun affected tests and final verification.

- [ ] **Step 5: Update and publish the PR**

Update the PR body with:

- summary and explicit out-of-scope items;
- reference image and implementation plan;
- direct embeds for the three committed PNGs;
- one-line description of what replaced the old Day split UI;
- preserved authentication/logout and Week/Month placeholder behavior;
- exact verification results;
- reviewer reading order.

Mark the PR ready for review. Do not merge it. Preserve the worktree for review feedback.

- [ ] **Step 6: Remove temporary artifacts**

Stop local servers and remove only task-created untracked logs, temporary screenshots, and build helpers. Keep the committed verification fixture, evidence PNGs, branch, and worktree. Confirm `git status --short` is clean.

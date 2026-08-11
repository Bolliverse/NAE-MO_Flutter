# New Item Save Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist a valid event or Todo from the unified new-item form and return to a refreshed Daily view.

**Architecture:** Keep the existing form-owned UI state. Add one pure parameter builder and an injectable asynchronous saver to `NewItemPage`; production reads `CreateTaskUseCase` through Riverpod, while tests inject deterministic callbacks. The router owns only the post-save Today invalidation and route restoration.

**Tech Stack:** Flutter 3.24.5, Dart 3.5.4, Riverpod 2.6.1, GoRouter 14.8.1, `flutter_test`.

---

## File map

- `docs/superpowers/specs/2026-08-10-new-item-save-design.md`: approved behavior and PR boundary.
- `docs/superpowers/plans/2026-08-10-new-item-save.md`: executable TDD plan.
- `test/features/task/presentation/pages/new_item_page_test.dart`: conversion, validation, progress, failure, retry, and success callback tests.
- `lib/features/task/presentation/pages/new_item_page.dart`: form validity, parameter conversion, use-case submission, and inline status UI.
- `test/widget_test.dart`: router-level save, return, and Today refresh regression.
- `lib/core/router/app_router.dart`: post-save Today invalidation and origin restoration.
- `docs/design/evidence/pr-new-item-save/new-item-save-ready-mobile.jpg`: reviewed 390x844 UI evidence.

This is exactly seven changed files, including the already committed design and this plan.

### Task 1: Specify page conversion and submission behavior

**Files:**
- Modify: `test/features/task/presentation/pages/new_item_page_test.dart`

- [ ] **Step 1: Add pure conversion tests before production code**

Import `Task`, `CreateTaskParams`, and `NewItemScheduleDraft`. Add table-driven tests that call a not-yet-existing `buildNewItemParams` with the following cases:

```dart
final cases = <({
  String name,
  NewItemScheduleDraft draft,
  bool hasTime,
  bool isAllDay,
  TaskKind kind,
})>[
  (
    name: 'timed event',
    draft: const NewItemScheduleDraft(
      startTime: TimeOfDay(hour: 9, minute: 30),
      endTime: TimeOfDay(hour: 10, minute: 30),
    ),
    hasTime: true,
    isAllDay: false,
    kind: TaskKind.event,
  ),
  (
    name: 'all-day event',
    draft: const NewItemScheduleDraft(
      eventMode: NewItemTimeMode.allDay,
    ),
    hasTime: false,
    isAllDay: true,
    kind: TaskKind.event,
  ),
  (
    name: 'timed Todo',
    draft: const NewItemScheduleDraft(
      kind: NewItemKind.todo,
      todoMode: NewItemTimeMode.timed,
      startTime: TimeOfDay(hour: 13, minute: 0),
      endTime: TimeOfDay(hour: 14, minute: 0),
    ),
    hasTime: true,
    isAllDay: false,
    kind: TaskKind.todo,
  ),
  (
    name: 'untimed Todo',
    draft: const NewItemScheduleDraft(kind: NewItemKind.todo),
    hasTime: false,
    isAllDay: false,
    kind: TaskKind.todo,
  ),
];
```

For each case, assert the trimmed title, normalized `DateTime(2026, 8, 3)`, nullable category, kind flags, and exact local start/end values.

- [ ] **Step 2: Add widget submission tests before production code**

Extend `_pump` with `NewItemSaver? saver` and `VoidCallback? onSaved`. Add focused tests that prove:

```dart
expect(_saveButton(tester).onPressed, isNull); // empty title
await tester.enterText(find.byKey(const Key('newItemTitleField')), '할 일');
await tester.tap(find.byKey(const Key('newItemTodoKind')));
await tester.pump();
expect(_saveButton(tester).onPressed, isNotNull); // untimed Todo
```

Use a `Completer<Result<Task>>` saver to assert a second tap does not start another request and the button shows `저장 중`. Complete it with `CacheFailure` and assert the inline live-region error appears, the title remains, and a retry starts a second request. Add a success case that asserts `onSaved` is called once and no failure message appears.

- [ ] **Step 3: Run the page tests and verify RED**

Run:

```powershell
flutter test test/features/task/presentation/pages/new_item_page_test.dart --reporter compact
```

Expected: compilation fails because `NewItemSaver`, `buildNewItemParams`, `saver`, and `onSaved` do not exist yet.

- [ ] **Step 4: Commit the single test file**

```powershell
git add -- test/features/task/presentation/pages/new_item_page_test.dart
git diff --cached --check
git commit -m "test: specify new item save flow"
```

### Task 2: Implement page conversion, validation, and asynchronous save

**Files:**
- Modify: `lib/features/task/presentation/pages/new_item_page.dart`
- Test: `test/features/task/presentation/pages/new_item_page_test.dart`

- [ ] **Step 1: Add the pure builder and saver seam**

Add these imports and public seam:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/create_task_use_case.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';

typedef NewItemSaver = Future<Result<Task>> Function(CreateTaskParams params);

CreateTaskParams buildNewItemParams({
  required String title,
  required DateTime selectedDate,
  required NewItemScheduleDraft draft,
  required String? categoryId,
}) {
  final local = selectedDate.toLocal();
  final date = DateTime(local.year, local.month, local.day);
  final hasTime = draft.activeMode == NewItemTimeMode.timed;
  DateTime? at(TimeOfDay? value) => value == null
      ? null
      : DateTime(date.year, date.month, date.day, value.hour, value.minute);

  return CreateTaskParams(
    title: title.trim(),
    kind: draft.kind == NewItemKind.event ? TaskKind.event : TaskKind.todo,
    targetDate: date,
    categoryId: categoryId,
    hasTime: hasTime,
    startDateTime: hasTime ? at(draft.startTime) : null,
    endDateTime: hasTime ? at(draft.endTime) : null,
    isAllDay: draft.activeMode == NewItemTimeMode.allDay,
  );
}
```

Convert `NewItemPage` to `ConsumerStatefulWidget`, add `NewItemSaver? saver` and required `VoidCallback onSaved`, and convert the state to `ConsumerState<NewItemPage>`.

- [ ] **Step 2: Add form validity and submission state**

Listen to `_titleController` so its trimmed value rebuilds the save button. Track:

```dart
bool _isSaving = false;
bool _saveFailed = false;

bool get _canSave {
  if (_isSaving || _titleController.text.trim().isEmpty) return false;
  if (!_draft.showsTimeFields) return true;
  return _draft.startTime != null &&
      _draft.endTime != null &&
      _draft.timeRangeError == null;
}
```

Clear `_saveFailed` whenever the user changes title, kind, category, mode, or time. Wrap editable form content in `AbsorbPointer(absorbing: _isSaving)`.
Make `_Header.onClose` nullable and disable it while saving. Ignore system-back close requests while a
save is pending so a completed write cannot silently land after the user has left the form.

- [ ] **Step 3: Submit through the use case**

Implement `_save` with an early duplicate guard, `buildNewItemParams`, and the injected or provider-backed saver:

```dart
Future<void> _save() async {
  if (!_canSave) return;
  setState(() {
    _isSaving = true;
    _saveFailed = false;
  });

  final params = buildNewItemParams(
    title: _titleController.text,
    selectedDate: widget.selectedDate,
    draft: _draft,
    categoryId: _selectedCategoryId,
  );
  final save = widget.saver ?? ref.read(createTaskUseCaseProvider).call;

  Result<Task> result;
  try {
    result = await save(params);
  } catch (_) {
    result = fail(const CacheFailure('new item save failed'));
  }
  if (!mounted) return;

  if (result.isSuccess) {
    widget.onSaved();
    return;
  }
  setState(() {
    _isSaving = false;
    _saveFailed = true;
  });
}
```

Import `CacheFailure` for the guarded exception path.

- [ ] **Step 4: Make save status visible and accessible**

Give `_Header` `canSave`, `isSaving`, and `onSave`. Enable the button only when `canSave`; render a 14px progress indicator plus `저장 중` while pending. Directly below the header divider, render this only on failure:

```dart
Semantics(
  key: const Key('newItemSaveError'),
  liveRegion: true,
  child: const Padding(
    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Text('항목을 저장하지 못했습니다. 다시 시도해 주세요.'),
  ),
)
```

- [ ] **Step 5: Run the page tests and verify GREEN**

Run:

```powershell
dart format lib/features/task/presentation/pages/new_item_page.dart test/features/task/presentation/pages/new_item_page_test.dart
flutter test test/features/task/presentation/pages/new_item_page_test.dart --reporter compact
```

Expected: all tests in the file pass.

- [ ] **Step 6: Commit the single production file**

The test file was already committed in Task 1; formatting must not create additional test changes.

```powershell
git add -- lib/features/task/presentation/pages/new_item_page.dart
git diff --cached --check
git commit -m "feat: save new calendar items"
```

### Task 3: Specify router return and Today refresh

**Files:**
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Add an integration regression before router code**

Allow `_pumpApp` to receive optional `TaskRepository` and `GetTodayOverviewUseCase`, resolving them once
so the save and refresh fakes can share state:

```dart
Future<void> _pumpApp(
  WidgetTester tester,
  _FakeAuthSessionRepository authRepository, {
  bool settle = true,
  TaskRepository? taskRepository,
  GetTodayOverviewUseCase? todayOverviewUseCase,
}) async {
  final resolvedTaskRepository = taskRepository ?? _EmptyTaskRepository();
  final resolvedOverviewUseCase =
      todayOverviewUseCase ?? _EmptyTodayOverviewUseCase();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionRepositoryProvider.overrideWithValue(authRepository),
        taskRepositoryProvider.overrideWithValue(resolvedTaskRepository),
        getTodayOverviewUseCaseProvider.overrideWithValue(
          resolvedOverviewUseCase,
        ),
      ],
      child: const App(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
```

Add a saving fake repository that captures `CreateTaskParams` and returns a concrete Todo:

```dart
class _SavingTaskRepository extends _EmptyTaskRepository {
  CreateTaskParams? createdParams;
  domain.Task? createdTask;

  @override
  Future<Result<domain.Task>> createTask(CreateTaskParams params) async {
    createdParams = params;
    createdTask = domain.Task(
      id: 'saved-task',
      title: params.title,
      kind: params.kind,
      targetDate: params.targetDate,
      categoryId: params.categoryId,
      isCompleted: false,
      hasTime: params.hasTime,
      startDateTime: params.startDateTime,
      endDateTime: params.endDateTime,
      isAllDay: params.isAllDay,
      isRecurring: false,
      createdAt: DateTime(2026, 8, 3, 12),
    );
    return success(createdTask!);
  }
}
```

Add a recording overview use case that increments `calls` and returns that created Todo in
`untimedTodos` after save:

```dart
class _RecordingTodayOverviewUseCase extends GetTodayOverviewUseCase {
  _RecordingTodayOverviewUseCase(this.repository)
      : super(repository, _UnusedCategoryRepository());

  final _SavingTaskRepository repository;
  int calls = 0;

  @override
  Future<Result<TodayOverview>> call(DateTime selectedDate) async {
    calls++;
    final task = repository.createdTask;
    final local = selectedDate.toLocal();
    return success(
      TodayOverview(
        date: DateTime(local.year, local.month, local.day),
        overdueTodos: const [],
        allDayEvents: const [],
        timelineItems: const [],
        untimedTodos: task == null
            ? const []
            : [TodayEntry(task: task, category: null)],
        completedTodos: const [],
      ),
    );
  }
}
```

The test should authenticate, set `selectedDateProvider` to `DateTime(2026, 8, 3)`, open the global add
action, switch to Todo, enter `리뷰 요청 보내기`, tap save, then assert:

```dart
expect(_routerOf(tester).routeInformationProvider.value.uri.path,
    AppRoutes.today);
expect(find.text('리뷰 요청 보내기'), findsOneWidget);
expect(overviewUseCase.calls, 2);
expect(repository.createdParams?.targetDate, DateTime(2026, 8, 3));
```

- [ ] **Step 2: Run the integration test and verify RED**

Run:

```powershell
flutter test test/widget_test.dart --plain-name "saving a new item returns to refreshed Today" --reporter compact
```

Expected: the add page cannot complete navigation because the router has no `onSaved` behavior yet.

- [ ] **Step 3: Commit the single integration test file**

```powershell
git add -- test/widget_test.dart
git diff --cached --check
git commit -m "test: specify save return and Today refresh"
```

### Task 4: Connect successful save to the router

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Add the post-save callback**

Import `today_view_model.dart` and provide this callback when constructing `NewItemPage`:

```dart
onSaved: () {
  ProviderScope.containerOf(context, listen: false)
      .invalidate(todayViewModelProvider);
  context.go(returnLocation);
},
```

Keep `onClose` unchanged so cancel never causes an unnecessary refresh.

- [ ] **Step 2: Run page and integration tests**

Run:

```powershell
dart format lib/core/router/app_router.dart test/widget_test.dart
flutter test test/features/task/presentation/pages/new_item_page_test.dart test/widget_test.dart --reporter compact
```

Expected: both files pass, including the new save-return test.

- [ ] **Step 3: Commit the single router file**

```powershell
git add -- lib/core/router/app_router.dart
git diff --cached --check
git commit -m "feat: refresh Today after item save"
```

### Task 5: Verify and capture mobile evidence

**Files:**
- Create: `docs/design/evidence/pr-new-item-save/new-item-save-ready-mobile.jpg`

- [ ] **Step 1: Run repository verification**

```powershell
dart format --output=none --set-exit-if-changed lib/features/task/presentation/pages/new_item_page.dart lib/core/router/app_router.dart test/features/task/presentation/pages/new_item_page_test.dart test/widget_test.dart
flutter test --reporter compact
flutter analyze --no-fatal-infos
git diff --check main...HEAD
```

Expected: tests pass; analyze exits 0 with no new warnings or errors; format and diff checks are clean.

- [ ] **Step 2: Exercise the actual Flutter web UI at 390x844**

Use a temporary visual entrypoint outside the seven committed files to open `NewItemPage` directly with deterministic categories. Switch to Todo, enter a title, confirm save is enabled, and verify the browser console has no errors. Delete the temporary entrypoint, local server logs, and any other runtime artifacts after capture.

- [ ] **Step 3: Save and inspect the screenshot**

Capture exactly `docs/design/evidence/pr-new-item-save/new-item-save-ready-mobile.jpg`. Inspect it for white background, readable Korean text, category-only color, enabled save affordance, and no overflow.

- [ ] **Step 4: Commit the single evidence file**

```powershell
git add -- docs/design/evidence/pr-new-item-save/new-item-save-ready-mobile.jpg
git diff --cached --check
git commit -m "docs: add new item save evidence"
```

### Task 6: Publish a reviewable PR

**Files:**
- No additional repository files.

- [ ] **Step 1: Confirm scope and one-file commit discipline**

```powershell
git diff --stat main...HEAD
git diff --name-only main...HEAD
git log --format="%h %s" main..HEAD
git status --short --branch
```

Expected: exactly seven changed files, every commit changes one file, and the worktree is clean.

- [ ] **Step 2: Push without merging**

```powershell
git push -u origin codex/new-item-save
```

- [ ] **Step 3: Open the PR**

Create a PR targeting `main` with a concise behavior summary, exact test/analyze results, the committed mobile screenshot embedded with its raw GitHub URL, and explicit exclusions. Leave it open for teammate review and do not merge it.

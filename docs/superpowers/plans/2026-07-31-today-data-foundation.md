# Today Data Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the event/todo distinction and target date, migrate Drift schema v1 safely, validate writes, and expose one categorized `TodayOverview` read model.

**Architecture:** Keep the physical `tasks` table and `Task` entity name for compatibility. Add `TaskKind` and normalized `targetDate`, preserve existing rows with a guided Drift v1-to-v2 migration, then combine Task and Category repositories in `GetTodayOverviewUseCase`. Every candidate is classified into exactly one Today section.

**Tech Stack:** Flutter, Dart 3.5, Drift 2.23.1, Riverpod 2.6.1, `flutter_test`, `drift_dev make-migrations`.

**Design:** `docs/superpowers/specs/2026-07-31-today-redesign-design.md`

**Official references:**

- https://drift.simonbinder.eu/migrations/
- https://drift.simonbinder.eu/migrations/tests/
- https://drift.simonbinder.eu/dart_api/tables/
- https://drift.simonbinder.eu/guides/datetime-migrations/

---

## File responsibilities

- `build.yaml`: guided migration database and output directories.
- `drift_schemas/app_database/`: immutable v1 and v2 schema snapshots.
- `lib/core/database/app_database.dart`: schema version and v1-to-v2 migration.
- `lib/core/database/app_database.steps.dart`: generated version-aware migration helper.
- `test/drift/app_database/`: generated schema verifier and legacy-data integrity test.
- `lib/features/task/domain/entities/task.dart`: event/todo kind and target date.
- `lib/features/task/domain/validation/task_validator.dart`: write invariants.
- `lib/features/task/data/`: v2 mapping, target-date queries, persistence failures.
- `lib/features/calendar/domain/entities/today_overview.dart`: five disjoint Today lists.
- `lib/features/calendar/domain/usecases/get_today_overview_use_case.dart`: fetch, join, group, sort.

All commits change exactly one path. RED tests are committed before the production path that makes them pass. Generated paths are committed individually.

---

### Task 1: Snapshot database schema v1

**Files:**

- Modify: `build.yaml`
- Create: `drift_schemas/app_database/drift_schema_v1.json`

- [ ] **Step 1: Configure guided migrations**

Preserve `generate_for` and add:

```yaml
options:
  databases:
    app_database: lib/core/database/app_database.dart
  schema_dir: drift_schemas/
  test_dir: test/drift/
```

- [ ] **Step 2: Commit only `build.yaml`**

```powershell
git add -- build.yaml
git diff --cached --check
git commit -m "build: configure drift migrations"
```

- [ ] **Step 3: Generate v1 before any table change**

```powershell
dart run drift_dev make-migrations
```

Expected: only `drift_schemas/app_database/drift_schema_v1.json` is created because a single version is known.

- [ ] **Step 4: Commit only the snapshot**

```powershell
git add -- drift_schemas/app_database/drift_schema_v1.json
git commit -m "test: snapshot database schema v1"
```

### Task 2: Extend the Task domain model

**Files:**

- Create: `test/features/task/domain/entities/task_test.dart`
- Modify: `lib/features/task/domain/entities/task.dart`
- Modify: `lib/features/task/data/mappers/task_mapper.dart`

- [ ] **Step 1: Write the failing kind test**

```dart
test('event and todo capabilities follow task kind', () {
  final date = DateTime(2026, 7, 31);
  final event = Task(
    id: 'event',
    title: '회의',
    kind: TaskKind.event,
    targetDate: date,
    isCompleted: false,
    hasTime: false,
    isAllDay: true,
    isRecurring: false,
    createdAt: date,
  );
  expect(event.isEvent, isTrue);
  expect(event.isTodo, isFalse);
});
```

- [ ] **Step 2: Run RED and commit only the test**

```powershell
flutter test --no-pub test/features/task/domain/entities/task_test.dart
git add -- test/features/task/domain/entities/task_test.dart
git commit -m "test: define task kind behavior"
```

Expected RED: `TaskKind`, `kind`, `targetDate`, and `isEvent` are missing.

- [ ] **Step 3: Add the minimal entity fields**

```dart
enum TaskKind { event, todo }

class Task {
  final TaskKind kind;
  final DateTime targetDate;

  bool get isEvent => kind == TaskKind.event;
  bool get isTodo => kind == TaskKind.todo;
}
```

Retain every existing field and constructor argument, adding `kind` and `targetDate` as required arguments. Commit only `task.dart` with `feat: distinguish events and todos`.

- [ ] **Step 4: Keep the v1 mapper source-compatible**

Until schema v2 exists, map legacy rows with:

```dart
kind: data.isAllDay ? TaskKind.event : TaskKind.todo,
targetDate: _dateOnly(data.startDateTime ?? data.createdAt),
```

Add a private `_dateOnly` helper. Commit only `task_mapper.dart` with `refactor: map legacy task dates`.

- [ ] **Step 5: Run GREEN**

Run the focused entity test. Expected: pass.

### Task 3: Define task validation

**Files:**

- Create: `test/features/task/domain/validation/task_validator_test.dart`
- Modify: `lib/core/errors/failure.dart`
- Create: `lib/features/task/domain/validation/task_validator.dart`

- [ ] **Step 1: Write failing validation tests**

Use a `_draft` helper and cover:

```dart
expect(TaskValidator.validate(_draft()), isNull);
expect(
  TaskValidator.validate(_draft(targetDate: DateTime(2026, 7, 31, 9)))?.message,
  '대상 날짜는 자정으로 정규화되어야 합니다.',
);
expect(
  TaskValidator.validate(_draft(isAllDay: true))?.message,
  '종일 항목은 일정만 사용할 수 있습니다.',
);
expect(
  TaskValidator.validate(_draft(kind: TaskKind.event))?.message,
  '일정은 시간 또는 종일 설정이 필요합니다.',
);
expect(
  TaskValidator.validate(_draft(hasTime: true))?.message,
  '시간 지정 항목은 시작과 종료 시각이 필요합니다.',
);
```

Also test completed events, time fields on untimed items, non-increasing ranges, and a start time outside `targetDate`.

- [ ] **Step 2: Run RED and commit only the test**

Expected RED: `TaskDraft`, `TaskValidator`, and `ValidationFailure` are missing. Commit with `test: define task validation rules`.

- [ ] **Step 3: Add `ValidationFailure`**

```dart
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
```

Commit only `failure.dart` with `feat: add validation failure`.

- [ ] **Step 4: Implement the validator**

`TaskDraft` holds `kind`, `targetDate`, `isCompleted`, `hasTime`, both times, and `isAllDay`. `TaskValidator.validate` returns the first `ValidationFailure?` in this order:

1. target date is local midnight including zero microseconds;
2. all-day is event-only;
3. event cannot be completed;
4. event must be timed or all-day;
5. all-day cannot have a time range;
6. timed item has both times;
7. untimed item has neither time;
8. end is after start;
9. start local date equals target date.

Commit only `task_validator.dart` with `feat: validate task scheduling rules`.

- [ ] **Step 5: Run GREEN**

```powershell
flutter test --no-pub test/features/task/domain/validation/task_validator_test.dart
```

### Task 4: Generate and test schema v2

**Files:**

- Modify: `lib/core/database/tables/task_table.dart`
- Modify: `lib/core/database/app_database.dart`
- Regenerate: `lib/core/database/app_database.g.dart`
- Create: `drift_schemas/app_database/drift_schema_v2.json`
- Create: `lib/core/database/app_database.steps.dart`
- Create: `test/drift/app_database/generated/schema_v1.dart`
- Create: `test/drift/app_database/generated/schema_v2.dart`
- Create: `test/drift/app_database/generated/schema.dart`
- Create: `test/drift/app_database/migration_test.dart`

- [ ] **Step 1: Add the stored columns**

```dart
TextColumn get kind =>
    textEnum<TaskKind>().withDefault(const Constant('todo'))();
DateTimeColumn get targetDate =>
    dateTime().withDefault(currentDateAndTime)();
```

Commit only `task_table.dart` with `feat: persist task kind and target date`.

- [ ] **Step 2: Make the database injectable and set v2**

```dart
AppDatabase([QueryExecutor? executor])
    : super(executor ?? conn.openConnection());

@override
int get schemaVersion => 2;
```

Commit only `app_database.dart` with `feat: bump planner database schema`.

- [ ] **Step 3: Regenerate only the database part**

```powershell
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/core/database/app_database.g.dart
```

Commit only `app_database.g.dart` with `build: regenerate planner database`.

- [ ] **Step 4: Generate guided migration artifacts**

Run `dart run drift_dev make-migrations`. Commit each generated path separately. Expected paths are the v2 JSON snapshot, `app_database.steps.dart`, three files under `test/drift/app_database/generated/`, and `migration_test.dart`.

- [ ] **Step 5: Verify the generated migration test is RED**

```powershell
flutter test --no-pub test/drift/app_database/migration_test.dart
```

Expected RED: v1 does not gain the two v2 columns.

- [ ] **Step 6: Implement `from1To2`**

Use generated `stepByStep`. Add both columns, then update legacy rows with stable v2 column names:

```dart
onUpgrade: stepByStep(
  from1To2: (m, schema) async {
    await m.addColumn(schema.taskTable, schema.taskTable.kind);
    await m.addColumn(schema.taskTable, schema.taskTable.targetDate);
    await customStatement('''
      UPDATE tasks
      SET kind = CASE WHEN is_all_day = 1 THEN 'event' ELSE 'todo' END,
          target_date = CAST(strftime(
            '%s', datetime(
              COALESCE(start_date_time, created_at),
              'unixepoch', 'localtime', 'start of day', 'utc'
            )
          ) AS INTEGER),
          is_completed = CASE WHEN is_all_day = 1 THEN 0 ELSE is_completed END,
          has_time = CASE
            WHEN is_all_day = 1 OR start_date_time IS NULL
              OR end_date_time IS NULL OR end_date_time <= start_date_time
            THEN 0 ELSE has_time END,
          start_date_time = CASE
            WHEN is_all_day = 1 OR start_date_time IS NULL
              OR end_date_time IS NULL OR end_date_time <= start_date_time
            THEN NULL ELSE start_date_time END,
          end_date_time = CASE
            WHEN is_all_day = 1 OR start_date_time IS NULL
              OR end_date_time IS NULL OR end_date_time <= start_date_time
            THEN NULL ELSE end_date_time END
    ''');
  },
),
```

Commit only `app_database.dart` with `feat: migrate planner data to schema v2`.

- [ ] **Step 7: Replace the generated empty integrity sample**

Keep the generated schema-validation loop. Insert three v1 rows and assert their v2 forms:

- completed all-day row becomes incomplete `event` at local midnight with cleared times;
- valid timed row becomes `todo` and retains its range;
- malformed timed row becomes untimed `todo` with cleared times.

Commit only `migration_test.dart` with `test: verify planner data migration`.

- [ ] **Step 8: Run GREEN**

Run the focused migration test. Expected: schema and data-integrity tests pass.

### Task 5: Persist and query v2 tasks

**Files:**

- Create: `test/features/task/data/repositories/task_repository_impl_test.dart`
- Modify: `lib/features/task/domain/usecases/params/create_task_params.dart`
- Modify: `lib/features/task/domain/usecases/params/update_task_params.dart`
- Modify: `lib/features/task/data/datasources/task_local_data_source.dart`
- Modify: `lib/features/task/domain/repositories/task_repository.dart`
- Modify: `lib/features/task/data/mappers/task_mapper.dart`
- Modify: `lib/features/task/data/datasources/task_local_data_source_impl.dart`
- Modify: `lib/features/task/data/repositories/task_repository_impl.dart`
- Modify: `lib/features/calendar/presentation/viewmodels/task_dock_viewmodel.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write failing persistence tests**

Use a fake DataSource to prove:

- `getTaskById` maps v2 kind/date;
- Today candidates preserve selected-date items and earlier incomplete todos;
- create/update pass kind/date and `clearTime` correctly;
- `CacheException` becomes `CacheFailure`.

Commit only the RED test with `test: cover today task persistence`.

- [ ] **Step 2: Expand create params**

Add required `TaskKind kind`, required `DateTime targetDate`, and `TaskDraft toDraft()` with `isCompleted: false`. Commit only this file with `feat: add task kind to create params`.

- [ ] **Step 3: Expand update params**

Add optional `kind`, `targetDate`, and `clearTime`. Add `TaskDraft resolve(Task current)` that merges the patch and writes both time values as null when `clearTime` is true. Commit only this file with `feat: support dated task updates`.

- [ ] **Step 4: Expand DataSource and Repository contracts**

Add to both boundaries, committing each interface separately:

```dart
Future<TaskTableData> getById(String id);
Future<List<TaskTableData>> getForTodayOverview(DateTime selectedDate);
```

```dart
Future<Result<Task>> getTaskById(String id);
Future<Result<List<Task>>> getTasksForTodayOverview(DateTime selectedDate);
```

- [ ] **Step 5: Switch the mapper from legacy derivation to v2 fields**

```dart
kind: data.kind,
targetDate: data.targetDate,
```

Commit only `task_mapper.dart` with `feat: map dated planner tasks`.

- [ ] **Step 6: Implement v2 Drift reads and writes**

- `getByDate` and `getByRange` compare normalized `targetDate`.
- `getById` exposes the existing private lookup.
- `getForTodayOverview` returns selected-date rows plus earlier incomplete todos.
- insert/update persist `kind` and `targetDate`.
- `clearTime` writes `Value(null)` to both time columns.

Use this Today predicate:

```dart
t.targetDate.equals(selected) |
    (t.kind.equals(TaskKind.todo) &
        t.targetDate.isSmallerThanValue(selected) &
        t.isCompleted.equals(false))
```

Commit only the DataSource implementation with `feat: query tasks by planner date`.

- [ ] **Step 7: Expose repository operations**

Map both new reads and convert all `CacheException`s to `CacheFailure`. Commit only the repository implementation with `feat: expose today task candidates`.

- [ ] **Step 8: Keep current callers compiling**

In legacy quick add, pass `TaskKind.todo` and the normalized selected date. In `_EmptyTaskRepository`, return not-found for `getTaskById` and an empty success for Today candidates. Commit each file separately.

- [ ] **Step 9: Run persistence GREEN**

```powershell
flutter test --no-pub test/features/task/data/repositories/task_repository_impl_test.dart
```

### Task 6: Validate all task writes

**Files:**

- Create: `test/features/task/domain/usecases/task_write_use_cases_test.dart`
- Modify: `lib/features/task/domain/usecases/create_task_use_case.dart`
- Modify: `lib/features/task/domain/usecases/update_task_use_case.dart`
- Modify: `lib/features/task/domain/usecases/schedule_task_use_case.dart`
- Modify: `lib/features/task/domain/usecases/toggle_complete_use_case.dart`

- [ ] **Step 1: Write failing use-case tests**

Prove invalid creates never insert, updates merge with stored Tasks before validation, scheduling sets normalized target date, and event completion never toggles storage. Commit only the RED test with `test: cover validated task writes`.

- [ ] **Step 2: Validate create**

Return `fail(failure)` from `TaskValidator.validate(params.toDraft())` before repository insertion. Commit only `create_task_use_case.dart`.

- [ ] **Step 3: Validate update**

Read with `getTaskById`, resolve the patch, validate it, preserve read failures, and update only after success. Commit only `update_task_use_case.dart`.

- [ ] **Step 4: Route scheduling through update validation**

Make `ScheduleTaskUseCase` depend on `UpdateTaskUseCase`. Pass both times, `hasTime: true`, and local midnight derived from the start. Commit only `schedule_task_use_case.dart`.

- [ ] **Step 5: Restrict completion to todos**

Read the Task first. Return `ValidationFailure('일정은 완료 상태를 가질 수 없습니다.')` for events; call `toggleComplete` only for todos. Commit only `toggle_complete_use_case.dart`.

- [ ] **Step 6: Run GREEN**

```powershell
flutter test --no-pub test/features/task
```

### Task 7: Build `TodayOverview`

**Files:**

- Create: `test/features/calendar/domain/usecases/get_today_overview_use_case_test.dart`
- Create: `lib/features/calendar/domain/entities/today_overview.dart`
- Create: `lib/features/calendar/domain/usecases/get_today_overview_use_case.dart`
- Generate: `lib/features/calendar/domain/usecases/get_today_overview_use_case.g.dart`

- [ ] **Step 1: Write the failing overview test**

Fake both repositories and verify all five groups, category joins, stable sorting, unchanged failures, and unique IDs after flattening:

```dart
final ids = [
  ...overview.overdueTodos,
  ...overview.allDayEvents,
  ...overview.timelineItems,
  ...overview.untimedTodos,
  ...overview.completedTodos,
].map((entry) => entry.task.id).toList();
expect(ids.toSet(), hasLength(ids.length));
```

Commit only the RED test with `test: define today overview grouping`.

- [ ] **Step 2: Add immutable read models**

```dart
class TodayEntry {
  final Task task;
  final Category? category;
  const TodayEntry({required this.task, this.category});
}

class TodayOverview {
  final DateTime date;
  final List<TodayEntry> overdueTodos;
  final List<TodayEntry> allDayEvents;
  final List<TodayEntry> timelineItems;
  final List<TodayEntry> untimedTodos;
  final List<TodayEntry> completedTodos;
}
```

Use a const constructor with all fields required. Commit only this file with `feat: add today overview model`.

- [ ] **Step 3: Implement fetch, join, classification, and sorting**

`GetTodayOverviewUseCase` reads Task candidates and Categories once each. It returns the first failure unchanged, maps categories by ID, then uses this exclusive order:

```dart
if (task.isTodo && task.isCompleted && isSelectedDate) {
  completedTodos.add(entry);
} else if (task.isTodo && !task.isCompleted && task.targetDate.isBefore(date)) {
  overdueTodos.add(entry);
} else if (task.isEvent && task.isAllDay && isSelectedDate) {
  allDayEvents.add(entry);
} else if (task.hasTime && isSelectedDate) {
  timelineItems.add(entry);
} else if (task.isTodo && !task.isCompleted && isSelectedDate) {
  untimedTodos.add(entry);
}
```

Sort with the design's primary keys and Task ID as the final tie breaker. Missing categories sort last. Register the UseCase through Riverpod. Commit only the use-case file with `feat: build today overview`.

- [ ] **Step 4: Generate only its provider**

```powershell
dart run build_runner build --delete-conflicting-outputs --build-filter=lib/features/calendar/domain/usecases/get_today_overview_use_case.g.dart
```

Commit only the generated file with `build: generate today overview provider`.

- [ ] **Step 5: Run GREEN**

Run the focused overview test. Expected: grouping, sorting, uniqueness, and failure tests pass.

### Task 8: Verify and publish the data PR

**Files:** No planned source changes.

- [ ] **Step 1: Format changed Dart paths**

```powershell
$dartFiles = git diff --name-only origin/main...HEAD -- '*.dart'
dart format $dartFiles
```

- [ ] **Step 2: Run all tests**

```powershell
flutter test --no-pub
```

Expected: all tests pass, none skipped.

- [ ] **Step 3: Analyze and build**

```powershell
flutter analyze --no-pub
flutter build web --release --no-pub
```

Expected: no new warning/error versus `origin/main`, and Web release succeeds.

- [ ] **Step 4: Verify one-file commits**

```powershell
git diff --check origin/main...HEAD
$bad = git rev-list --reverse origin/main..HEAD | ForEach-Object {
  $count = (git diff-tree --no-commit-id --name-only -r $_ | Measure-Object).Count
  if ($count -ne 1) { "$_ $count" }
}
if ($bad) { $bad; exit 1 }
```

- [ ] **Step 5: Request code review**

Use `requesting-code-review` for `origin/main...HEAD`. Resolve every Critical and Important issue with a new RED/GREEN cycle.

- [ ] **Step 6: Push and open the PR**

Target `main`. Explain the v1-to-v2 conversion rules, generated Drift verification, exact local checks, and that visible Today UI is the next stacked PR.

- [ ] **Step 7: Clean temporary output**

Delete only task-created build/test/browser temporary paths after resolving their exact absolute locations. Keep committed schema snapshots and generated migration tests. Finish with a clean `git status --short --branch`.

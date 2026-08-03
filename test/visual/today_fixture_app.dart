import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nae_mo/app.dart';
import 'package:nae_mo/core/providers/selected_date_provider.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/auth/auth_providers.dart';
import 'package:nae_mo/features/auth/domain/entities/auth_session.dart';
import 'package:nae_mo/features/auth/domain/repositories/auth_session_repository.dart';
import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/calendar/domain/usecases/get_today_overview_use_case.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/toggle_complete_use_case.dart';

const _showEmptyState = bool.fromEnvironment('TODAY_EMPTY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  Intl.defaultLocale = 'ko';

  runApp(
    ProviderScope(
      overrides: [
        authSessionRepositoryProvider.overrideWithValue(
          const _FixtureAuthSessionRepository(),
        ),
        selectedDateProvider.overrideWith(_FixtureSelectedDate.new),
        getTodayOverviewUseCaseProvider.overrideWithValue(
          _FixtureGetTodayOverviewUseCase(empty: _showEmptyState),
        ),
        toggleCompleteUseCaseProvider.overrideWithValue(
          _FixtureToggleCompleteUseCase(),
        ),
      ],
      child: const App(),
    ),
  );
}

class _FixtureSelectedDate extends SelectedDate {
  @override
  DateTime build() => DateTime(2026, 8, 3);
}

class _FixtureAuthSessionRepository implements AuthSessionRepository {
  const _FixtureAuthSessionRepository();

  static const _session = AuthenticatedSession(
    uid: 'today-visual-fixture',
    provider: AuthProviderType.apple,
  );

  @override
  Future<Result<AuthSession>> restoreSession() async => success(_session);

  @override
  Future<Result<AuthSession>> signIn(AuthProviderType provider) async =>
      success(_session);

  @override
  Future<Result<AuthSession>> signOut() async =>
      success(const UnauthenticatedSession());
}

class _FixtureGetTodayOverviewUseCase extends GetTodayOverviewUseCase {
  _FixtureGetTodayOverviewUseCase({required bool empty})
      : _empty = empty,
        super(_UnusedTaskRepository(), _UnusedCategoryRepository());

  final bool _empty;

  static const _work = Category(
    id: 'work',
    name: '업무',
    color: 0xFF6750A4,
    sortOrder: 0,
  );
  static const _personal = Category(
    id: 'personal',
    name: '개인',
    color: 0xFF006A6A,
    sortOrder: 1,
  );
  static const _health = Category(
    id: 'health',
    name: '건강',
    color: 0xFF9C5C00,
    sortOrder: 2,
  );

  @override
  Future<Result<TodayOverview>> call(DateTime selectedDate) async {
    final local = selectedDate.toLocal();
    final date = DateTime(local.year, local.month, local.day);
    if (_empty) return success(_emptyOverview(date));

    return success(
      TodayOverview(
        date: date,
        overdueTodos: [
          _entry(
            id: 'overdue-review',
            title: '지난 회의록 정리',
            kind: TaskKind.todo,
            targetDate: date.subtract(const Duration(days: 3)),
            category: _work,
            createdHour: 8,
          ),
          _entry(
            id: 'overdue-reservation',
            title: '병원 예약 확인',
            kind: TaskKind.todo,
            targetDate: date.subtract(const Duration(days: 1)),
            category: _health,
            createdHour: 9,
          ),
        ],
        allDayEvents: [
          _entry(
            id: 'all-day-release',
            title: 'NAE MO 첫 화면 리뷰',
            kind: TaskKind.event,
            targetDate: date,
            category: _work,
            isAllDay: true,
            createdHour: 10,
          ),
          _entry(
            id: 'all-day-birthday',
            title: '친구 생일',
            kind: TaskKind.event,
            targetDate: date,
            category: _personal,
            isAllDay: true,
            createdHour: 11,
          ),
        ],
        timelineItems: [
          _entry(
            id: 'timeline-sync',
            title: '팀 스탠드업',
            kind: TaskKind.event,
            targetDate: date,
            category: _work,
            startHour: 9,
            startMinute: 30,
            endHour: 10,
            endMinute: 0,
            createdHour: 12,
          ),
          _entry(
            id: 'timeline-feedback',
            title: '프로토타입 피드백 반영',
            kind: TaskKind.todo,
            targetDate: date,
            category: _work,
            startHour: 11,
            endHour: 12,
            createdHour: 13,
          ),
          _entry(
            id: 'timeline-dinner',
            title: '저녁 약속',
            kind: TaskKind.event,
            targetDate: date,
            category: _personal,
            startHour: 18,
            startMinute: 30,
            endHour: 20,
            createdHour: 14,
          ),
        ],
        untimedTodos: [
          _entry(
            id: 'untimed-pr',
            title: '리뷰 요청 메시지 작성',
            kind: TaskKind.todo,
            targetDate: date,
            category: _work,
            createdHour: 15,
          ),
          _entry(
            id: 'untimed-grocery',
            title: '장보기 목록 확인',
            kind: TaskKind.todo,
            targetDate: date,
            category: _personal,
            createdHour: 16,
          ),
          _entry(
            id: 'untimed-walk',
            title: '산책 30분',
            kind: TaskKind.todo,
            targetDate: date,
            category: _health,
            createdHour: 17,
          ),
        ],
        completedTodos: [
          _entry(
            id: 'completed-plan',
            title: '오늘 할 일 정리',
            kind: TaskKind.todo,
            targetDate: date,
            category: _work,
            isCompleted: true,
            createdHour: 6,
          ),
          _entry(
            id: 'completed-reading',
            title: '아침 독서 20분',
            kind: TaskKind.todo,
            targetDate: date,
            category: _personal,
            isCompleted: true,
            createdHour: 7,
          ),
        ],
      ),
    );
  }

  TodayOverview _emptyOverview(DateTime date) => TodayOverview(
        date: date,
        overdueTodos: const [],
        allDayEvents: const [],
        timelineItems: const [],
        untimedTodos: const [],
        completedTodos: const [],
      );

  TodayEntry _entry({
    required String id,
    required String title,
    required TaskKind kind,
    required DateTime targetDate,
    required Category category,
    required int createdHour,
    bool isCompleted = false,
    bool isAllDay = false,
    int? startHour,
    int startMinute = 0,
    int? endHour,
    int endMinute = 0,
  }) {
    final hasTime = startHour != null;
    return TodayEntry(
      task: Task(
        id: id,
        title: title,
        kind: kind,
        targetDate: targetDate,
        categoryId: category.id,
        isCompleted: isCompleted,
        hasTime: hasTime,
        startDateTime: hasTime
            ? DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                startHour,
                startMinute,
              )
            : null,
        endDateTime: endHour == null
            ? null
            : DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                endHour,
                endMinute,
              ),
        isAllDay: isAllDay,
        isRecurring: false,
        createdAt: DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          createdHour,
        ),
      ),
      category: category,
    );
  }
}

class _FixtureToggleCompleteUseCase extends ToggleCompleteUseCase {
  _FixtureToggleCompleteUseCase() : super(_UnusedTaskRepository());

  @override
  Future<Result<Task>> call(String id) async => success(
        Task(
          id: id,
          title: 'fixture todo',
          kind: TaskKind.todo,
          targetDate: DateTime(2026, 8, 3),
          isCompleted: true,
          hasTime: false,
          isAllDay: false,
          isRecurring: false,
          createdAt: DateTime(2026, 8, 3),
        ),
      );
}

class _UnusedTaskRepository implements TaskRepository {
  @override
  Future<Result<Task>> getTaskById(String id) => throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksByDate(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksByRange(DateTime start, DateTime end) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getUnscheduledTasks() =>
      throw UnimplementedError();

  @override
  Future<Result<List<Task>>> getTasksForTodayOverview(DateTime selectedDate) =>
      throw UnimplementedError();

  @override
  Future<Result<Task>> createTask(CreateTaskParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<Task>> updateTask(UpdateTaskParams params) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteTask(String id) => throw UnimplementedError();

  @override
  Future<Result<Task>> toggleComplete(String id) => throw UnimplementedError();
}

class _UnusedCategoryRepository implements CategoryRepository {
  @override
  Future<Result<List<Category>>> getCategories() => throw UnimplementedError();

  @override
  Future<Result<Category>> createCategory({
    required String name,
    required int color,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteCategory(String id) => throw UnimplementedError();
}

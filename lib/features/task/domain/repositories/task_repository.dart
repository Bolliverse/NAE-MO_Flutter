import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

abstract interface class TaskRepository {
  Future<Result<Task>> getTaskById(String id);

  /// 특정 날짜의 태스크 조회 (시간 있는 태스크 + 종일 태스크)
  Future<Result<List<Task>>> getTasksByDate(DateTime date);

  /// 날짜 범위의 태스크 조회 (Week/Month View)
  Future<Result<List<Task>>> getTasksByRange(DateTime start, DateTime end);

  /// Task Dock — 미배정(시간 없는, 미완료) 태스크
  Future<Result<List<Task>>> getUnscheduledTasks();

  Future<Result<List<Task>>> getTasksForTodayOverview(DateTime selectedDate);

  Future<Result<Task>> createTask(CreateTaskParams params);
  Future<Result<Task>> updateTask(UpdateTaskParams params);
  Future<Result<void>> deleteTask(String id);
  Future<Result<Task>> toggleComplete(String id);
}

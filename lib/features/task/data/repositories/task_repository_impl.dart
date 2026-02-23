import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source.dart';
import 'package:nae_mo/features/task/data/mappers/task_mapper.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _dataSource;
  final TaskMapper _mapper;

  const TaskRepositoryImpl({
    required TaskLocalDataSource dataSource,
    required TaskMapper mapper,
  })  : _dataSource = dataSource,
        _mapper = mapper;

  @override
  Future<Result<List<Task>>> getTasksByDate(DateTime date) async {
    try {
      final data = await _dataSource.getByDate(date);
      return success(_mapper.toEntityList(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<List<Task>>> getTasksByRange(
      DateTime start, DateTime end) async {
    try {
      final data = await _dataSource.getByRange(start, end);
      return success(_mapper.toEntityList(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<List<Task>>> getUnscheduledTasks() async {
    try {
      final data = await _dataSource.getUnscheduled();
      return success(_mapper.toEntityList(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<Task>> createTask(CreateTaskParams params) async {
    try {
      final data = await _dataSource.insert(const Uuid().v4(), params);
      return success(_mapper.toEntity(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<Task>> updateTask(UpdateTaskParams params) async {
    try {
      final data = await _dataSource.update(params);
      return success(_mapper.toEntity(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    try {
      await _dataSource.delete(id);
      return success(null);
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<Task>> toggleComplete(String id) async {
    try {
      final data = await _dataSource.toggleComplete(id);
      return success(_mapper.toEntity(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }
}

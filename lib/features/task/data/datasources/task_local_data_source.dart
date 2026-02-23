import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/features/task/domain/usecases/params/create_task_params.dart';
import 'package:nae_mo/features/task/domain/usecases/params/update_task_params.dart';

abstract interface class TaskLocalDataSource {
  Future<List<TaskTableData>> getByDate(DateTime date);
  Future<List<TaskTableData>> getByRange(DateTime start, DateTime end);
  Future<List<TaskTableData>> getUnscheduled();
  Future<TaskTableData> insert(String id, CreateTaskParams params);
  Future<TaskTableData> update(UpdateTaskParams params);
  Future<void> delete(String id);
  Future<TaskTableData> toggleComplete(String id);
}

import 'package:nae_mo/core/database/app_database_provider.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source.dart';
import 'package:nae_mo/features/task/data/datasources/task_local_data_source_impl.dart';
import 'package:nae_mo/features/task/data/mappers/task_mapper.dart';
import 'package:nae_mo/features/task/data/repositories/task_repository_impl.dart';
import 'package:nae_mo/features/task/domain/repositories/task_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_repository_provider.g.dart';

@riverpod
TaskLocalDataSource taskLocalDataSource(TaskLocalDataSourceRef ref) =>
    TaskLocalDataSourceImpl(ref.read(appDatabaseProvider));

@Riverpod(keepAlive: true)
TaskRepository taskRepository(TaskRepositoryRef ref) => TaskRepositoryImpl(
      dataSource: ref.read(taskLocalDataSourceProvider),
      mapper: const TaskMapper(),
    );

import 'package:nae_mo/core/database/app_database_provider.dart';
import 'package:nae_mo/features/category/data/datasources/category_local_data_source.dart';
import 'package:nae_mo/features/category/data/datasources/category_local_data_source_impl.dart';
import 'package:nae_mo/features/category/data/mappers/category_mapper.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_impl.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_repository_provider.g.dart';

@riverpod
CategoryLocalDataSource categoryLocalDataSource(
    CategoryLocalDataSourceRef ref) =>
    CategoryLocalDataSourceImpl(ref.read(appDatabaseProvider));

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(CategoryRepositoryRef ref) =>
    CategoryRepositoryImpl(
      dataSource: ref.read(categoryLocalDataSourceProvider),
      mapper: const CategoryMapper(),
    );

import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/data/datasources/category_local_data_source.dart';
import 'package:nae_mo/features/category/data/mappers/category_mapper.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:uuid/uuid.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _dataSource;
  final CategoryMapper _mapper;

  const CategoryRepositoryImpl({
    required CategoryLocalDataSource dataSource,
    required CategoryMapper mapper,
  })  : _dataSource = dataSource,
        _mapper = mapper;

  @override
  Future<Result<List<Category>>> getCategories() async {
    try {
      final data = await _dataSource.getAll();
      return success(_mapper.toEntityList(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<Category>> createCategory({
    required String name,
    required int color,
  }) async {
    try {
      final existing = await _dataSource.getAll();
      final sortOrder = existing.length;
      final data = await _dataSource.insert(
        id: const Uuid().v4(),
        name: name,
        color: color,
        sortOrder: sortOrder,
      );
      return success(_mapper.toEntity(data));
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    try {
      await _dataSource.delete(id);
      return success(null);
    } on CacheException catch (e) {
      return fail(CacheFailure(e.message));
    }
  }
}

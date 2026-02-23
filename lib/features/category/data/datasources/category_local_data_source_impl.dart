import 'package:drift/drift.dart';
import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/core/errors/app_exception.dart';
import 'package:nae_mo/features/category/data/datasources/category_local_data_source.dart';

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final AppDatabase _db;
  const CategoryLocalDataSourceImpl(this._db);

  @override
  Future<List<CategoryTableData>> getAll() async {
    try {
      return await (_db.select(_db.categoryTable)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();
    } catch (e) {
      throw CacheException('카테고리를 불러오는 데 실패했습니다: $e');
    }
  }

  @override
  Future<CategoryTableData> insert({
    required String id,
    required String name,
    required int color,
    required int sortOrder,
  }) async {
    try {
      await _db.into(_db.categoryTable).insert(
            CategoryTableCompanion(
              id: Value(id),
              name: Value(name),
              color: Value(color),
              sortOrder: Value(sortOrder),
            ),
          );
      return await (_db.select(_db.categoryTable)
            ..where((t) => t.id.equals(id)))
          .getSingle();
    } catch (e) {
      throw CacheException('카테고리를 생성하는 데 실패했습니다: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (_db.delete(_db.categoryTable)
            ..where((t) => t.id.equals(id)))
          .go();
    } catch (e) {
      throw CacheException('카테고리를 삭제하는 데 실패했습니다: $e');
    }
  }
}

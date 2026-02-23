import 'package:nae_mo/core/database/app_database.dart';

abstract interface class CategoryLocalDataSource {
  Future<List<CategoryTableData>> getAll();
  Future<CategoryTableData> insert({
    required String id,
    required String name,
    required int color,
    required int sortOrder,
  });
  Future<void> delete(String id);
}

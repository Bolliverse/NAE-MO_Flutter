import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';

abstract interface class CategoryRepository {
  Future<Result<List<Category>>> getCategories();
  Future<Result<Category>> createCategory({
    required String name,
    required int color,
  });
  Future<Result<void>> deleteCategory(String id);
}

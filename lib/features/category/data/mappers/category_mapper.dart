import 'package:nae_mo/core/database/app_database.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';

class CategoryMapper {
  const CategoryMapper();

  Category toEntity(CategoryTableData data) => Category(
        id: data.id,
        name: data.name,
        color: data.color,
        sortOrder: data.sortOrder,
      );

  List<Category> toEntityList(List<CategoryTableData> dataList) =>
      dataList.map(toEntity).toList();
}

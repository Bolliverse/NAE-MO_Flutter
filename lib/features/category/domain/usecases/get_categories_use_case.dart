import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:nae_mo/features/category/data/repositories/category_repository_provider.dart';

part 'get_categories_use_case.g.dart';

class GetCategoriesUseCase {
  final CategoryRepository _repository;
  const GetCategoriesUseCase(this._repository);

  Future<Result<List<Category>>> call() => _repository.getCategories();
}

@riverpod
GetCategoriesUseCase getCategoriesUseCase(GetCategoriesUseCaseRef ref) =>
    GetCategoriesUseCase(ref.read(categoryRepositoryProvider));

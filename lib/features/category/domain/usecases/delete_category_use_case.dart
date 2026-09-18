import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_provider.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';

class DeleteCategoryUseCase {
  const DeleteCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteCategory(id);
}

final deleteCategoryUseCaseProvider =
    Provider.autoDispose<DeleteCategoryUseCase>(
  (ref) => DeleteCategoryUseCase(ref.watch(categoryRepositoryProvider)),
);

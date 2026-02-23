import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_category_use_case.g.dart';

class CreateCategoryParams {
  final String name;
  final int color;
  const CreateCategoryParams({required this.name, required this.color});
}

class CreateCategoryUseCase {
  final CategoryRepository _repository;
  const CreateCategoryUseCase(this._repository);

  Future<Result<Category>> call(CreateCategoryParams params) =>
      _repository.createCategory(name: params.name, color: params.color);
}

@riverpod
CreateCategoryUseCase createCategoryUseCase(CreateCategoryUseCaseRef ref) =>
    CreateCategoryUseCase(ref.read(categoryRepositoryProvider));

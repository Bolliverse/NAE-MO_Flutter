import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/data/repositories/category_repository_provider.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/repositories/category_repository.dart';

class UpdateCategoryParams {
  const UpdateCategoryParams({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final int color;
}

class UpdateCategoryUseCase {
  const UpdateCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<Result<Category>> call(UpdateCategoryParams params) async {
    final name = params.name.trim();
    if (name.isEmpty) return fail(const ValidationFailure('이름을 입력해 주세요.'));
    return _repository.updateCategory(
      id: params.id,
      name: name,
      color: params.color,
    );
  }
}

final updateCategoryUseCaseProvider =
    Provider.autoDispose<UpdateCategoryUseCase>(
  (ref) => UpdateCategoryUseCase(ref.watch(categoryRepositoryProvider)),
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/usecases/get_categories_use_case.dart';

typedef NewItemCategoryLoader = Future<Result<List<Category>>> Function();

enum NewItemCategoryStatus {
  loading,
  loaded,
  failed,
}

@immutable
class NewItemCategoryState {
  const NewItemCategoryState._({
    required this.status,
    this.categories = const <Category>[],
  });

  const NewItemCategoryState.loading()
      : this._(status: NewItemCategoryStatus.loading);

  factory NewItemCategoryState.loaded(List<Category> categories) {
    final sorted = List<Category>.of(categories)
      ..sort((left, right) {
        final sortOrder = left.sortOrder.compareTo(right.sortOrder);
        return sortOrder != 0 ? sortOrder : left.id.compareTo(right.id);
      });
    return NewItemCategoryState._(
      status: NewItemCategoryStatus.loaded,
      categories: List<Category>.unmodifiable(sorted),
    );
  }

  const NewItemCategoryState.failed()
      : this._(status: NewItemCategoryStatus.failed);

  final NewItemCategoryStatus status;
  final List<Category> categories;

  Category? categoryFor(String? id) {
    if (id == null) return null;

    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}

class NewItemCategoryInput extends ConsumerStatefulWidget {
  const NewItemCategoryInput({
    required this.selectedId,
    required this.onSelected,
    this.loader,
    super.key,
  });

  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final NewItemCategoryLoader? loader;

  @override
  ConsumerState<NewItemCategoryInput> createState() =>
      _NewItemCategoryInputState();
}

class _NewItemCategoryInputState extends ConsumerState<NewItemCategoryInput> {
  NewItemCategoryState _state = const NewItemCategoryState.loading();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state.status) {
      NewItemCategoryStatus.loading => const _CategoryLoading(),
      NewItemCategoryStatus.failed => _CategoryFailure(onRetry: _load),
      NewItemCategoryStatus.loaded => _CategoryButton(
          selected: _state.categoryFor(widget.selectedId),
          onTap: _showPicker,
        ),
    };
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _state = const NewItemCategoryState.loading());
    }

    try {
      final loader =
          widget.loader ?? () => ref.read(getCategoriesUseCaseProvider).call();
      final result = await loader();
      if (!mounted) return;

      setState(() {
        _state = result.isSuccess
            ? NewItemCategoryState.loaded(result.data!)
            : const NewItemCategoryState.failed();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NewItemCategoryState.failed());
    }
  }

  Future<void> _showPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _CategorySheet(
        categories: _state.categories,
        selectedId: widget.selectedId,
        onSelected: (id) {
          widget.onSelected(id);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _CategoryLoading extends StatelessWidget {
  const _CategoryLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('newItemCategoryLoading'),
      label: '카테고리 불러오는 중',
      liveRegion: true,
      child: ExcludeSemantics(
        child: _CategorySurface(
          child: Row(
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 20,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '카테고리 불러오는 중',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFailure extends StatelessWidget {
  const _CategoryFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('newItemCategoryError'),
      liveRegion: true,
      child: _CategorySurface(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '카테고리를 불러오지 못했습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton(
              key: const Key('newItemCategoryRetryButton'),
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.selected, required this.onTap});

  final Category? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selected?.name ?? '카테고리 없음';

    return Semantics(
      key: const Key('newItemCategoryButton'),
      label: '카테고리, $label',
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _CategoryDot(category: selected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF202124),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF667085),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySurface extends StatelessWidget {
  const _CategorySurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD0D5DD)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: child,
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final hasSelectedCategory =
        categories.any((category) => category.id == selectedId);

    return Container(
      key: const Key('newItemCategorySheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.68,
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '카테고리 선택',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF202124),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _CategoryOption(
                  key: const Key('newItemCategory-none'),
                  category: null,
                  selected: !hasSelectedCategory,
                  onTap: () => onSelected(null),
                ),
                for (final category in categories)
                  _CategoryOption(
                    key: Key('newItemCategory-${category.id}'),
                    category: category,
                    selected: category.id == selectedId,
                    onTap: () => onSelected(category.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Category? category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = category?.name ?? '카테고리 없음';

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF0F1F3)),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _CategoryDot(category: category),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF202124),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2E4175),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  const _CategoryDot({required this.category});

  final Category? category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: category == null
            ? Colors.white
            : Color(category!.color).withAlpha(255),
        border: category == null
            ? Border.all(color: const Color(0xFF98A2B3))
            : null,
      ),
    );
  }
}

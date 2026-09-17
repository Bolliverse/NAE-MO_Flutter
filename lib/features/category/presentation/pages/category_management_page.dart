import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nae_mo/core/errors/failure.dart';
import 'package:nae_mo/core/utils/result.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/category/domain/usecases/create_category_use_case.dart';
import 'package:nae_mo/features/category/domain/usecases/get_categories_use_case.dart';
import 'package:nae_mo/features/category/domain/usecases/update_category_use_case.dart';

typedef CategoryLoader = Future<Result<List<Category>>> Function();
typedef CategoryCreator = Future<Result<Category>> Function(
  CreateCategoryParams params,
);
typedef CategoryUpdater = Future<Result<Category>> Function(
  UpdateCategoryParams params,
);

const _navy = Color(0xFF2E4175);
const _border = Color(0xFFE4E7EC);

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({
    required this.onClose,
    this.loader,
    this.creator,
    this.updater,
    this.onChanged,
    super.key,
  });

  final VoidCallback onClose;
  final CategoryLoader? loader;
  final CategoryCreator? creator;
  final CategoryUpdater? updater;
  final VoidCallback? onChanged;

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState
    extends ConsumerState<CategoryManagementPage> {
  _CategoryListStatus _status = _CategoryListStatus.loading;
  List<Category> _categories = const [];

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onClose();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onClose: widget.onClose),
                  const Divider(height: 1, color: _border),
                  Expanded(child: _buildContent()),
                  if (_status == _CategoryListStatus.loaded)
                    _AddBar(onPressed: () => _showEditor()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_status) {
      _CategoryListStatus.loading => const _CategoryLoading(),
      _CategoryListStatus.failed => _CategoryFailure(onRetry: _load),
      _CategoryListStatus.loaded => _CategoryList(
          categories: _categories,
          onEdit: _showEditor,
        ),
    };
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _status = _CategoryListStatus.loading);
    }

    final load = widget.loader ?? ref.read(getCategoriesUseCaseProvider).call;
    Result<List<Category>> result;
    try {
      result = await load();
    } catch (_) {
      result = fail(const CacheFailure('category load failed'));
    }
    if (!mounted) return;

    setState(() {
      if (result.isSuccess) {
        _categories = _sorted(result.data!);
        _status = _CategoryListStatus.loaded;
      } else {
        _status = _CategoryListStatus.failed;
      }
    });
  }

  Future<void> _showEditor([Category? category]) async {
    final CategoryCreator save;
    if (category == null) {
      save = widget.creator ?? ref.read(createCategoryUseCaseProvider).call;
    } else {
      final update =
          widget.updater ?? ref.read(updateCategoryUseCaseProvider).call;
      save = (params) => update(UpdateCategoryParams(
            id: category.id,
            name: params.name,
            color: params.color,
          ));
    }
    final saved = await showModalBottomSheet<Category>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _CategoryEditorSheet(
        save: save,
        category: category,
      ),
    );
    if (!mounted || saved == null) return;

    setState(() => _categories = _sorted([
          ..._categories.where((item) => item.id != saved.id),
          saved,
        ]));
    widget.onChanged?.call();
  }
}

enum _CategoryListStatus { loading, loaded, failed }

List<Category> _sorted(Iterable<Category> categories) {
  final sorted = List<Category>.of(categories)
    ..sort((left, right) {
      final sortOrder = left.sortOrder.compareTo(right.sortOrder);
      return sortOrder != 0 ? sortOrder : left.id.compareTo(right.id);
    });
  return List.unmodifiable(sorted);
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            key: const Key('categoryCloseButton'),
            onPressed: onClose,
            tooltip: '닫기',
            constraints: const BoxConstraints.tightFor(width: 56, height: 56),
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Text(
              '카테고리 관리',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF202124),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _CategoryLoading extends StatelessWidget {
  const _CategoryLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('categoryListLoading'),
      label: '카테고리 불러오는 중',
      liveRegion: true,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(color: _navy, strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text('카테고리 불러오는 중'),
          ],
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
      key: const Key('categoryListError'),
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '카테고리를 불러오지 못했습니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF475467),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('categoryListRetryButton'),
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: _navy),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories, required this.onEdit});

  final List<Category> categories;
  final ValueChanged<Category> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            '색상은 일정과 Todo를 구분할 때 사용됩니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
          ),
        ),
        Expanded(
          child: categories.isEmpty
              ? const Center(
                  child: Text(
                    '아직 카테고리가 없습니다.',
                    key: Key('categoryEmptyState'),
                    style: TextStyle(color: Color(0xFF667085)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 42,
                    color: Color(0xFFF0F1F3),
                  ),
                  itemBuilder: (context, index) => _CategoryRow(
                    category: categories[index],
                    onTap: () => onEdit(categories[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: Key('categoryRow-${category.id}'),
      container: true,
      label: '${category.name}, 카테고리 수정',
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _ColorDot(color: Color(category.color).withAlpha(255)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF202124),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF98A2B3), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  const _AddBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: FilledButton.icon(
          key: const Key('categoryAddButton'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            '새 카테고리',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({required this.save, this.category});

  final CategoryCreator save;
  final Category? category;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _nameController = TextEditingController();
  late int _selectedColor;
  late List<_CategoryColor> _colors;
  var _isSaving = false;
  var _saveFailed = false;

  bool get _isEditing => widget.category != null;
  bool get _canCreate =>
      !_isSaving &&
      _nameController.text.trim().isNotEmpty &&
      (!_isEditing ||
          _nameController.text.trim() != widget.category!.name ||
          _selectedColor != widget.category!.color);

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
    _selectedColor = widget.category?.color ?? _palette.first.value;
    _colors = [
      ..._palette,
      if (!_palette.any((color) => color.value == _selectedColor))
        _CategoryColor('기존 색상', _selectedColor),
    ];
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Padding(
        key: Key(_isEditing ? 'categoryEditSheet' : 'categoryCreateSheet'),
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? '카테고리 수정' : '새 카테고리',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF202124),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    key: const Key('categoryCreateCancelButton'),
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    tooltip: '취소',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SheetLabel('이름'),
              const SizedBox(height: 8),
              TextField(
                key: const Key('categoryNameField'),
                controller: _nameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_canCreate) _create();
                },
                decoration: InputDecoration(
                  hintText: '카테고리 이름',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _navy, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const _SheetLabel('색상'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0; index < _colors.length; index++)
                    _ColorOption(
                      index: index,
                      option: _colors[index],
                      selected: _colors[index].value == _selectedColor,
                      enabled: !_isSaving,
                      onSelected: () => setState(() {
                        _selectedColor = _colors[index].value;
                        _saveFailed = false;
                      }),
                    ),
                ],
              ),
              if (_saveFailed) ...[
                const SizedBox(height: 16),
                Semantics(
                  key: const Key('categoryCreateError'),
                  liveRegion: true,
                  child: Text(
                    _isEditing
                        ? '카테고리를 수정하지 못했습니다. 다시 시도해 주세요.'
                        : '카테고리를 만들지 못했습니다. 다시 시도해 주세요.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                key: const Key('categoryCreateButton'),
                onPressed: _canCreate ? _create : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: _canCreate || _isSaving ? _navy : null,
                  foregroundColor: Colors.white,
                  disabledForegroundColor:
                      _isSaving ? Colors.white : const Color(0xFF98A2B3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _canCreate || _isSaving
                          ? _navy
                          : const Color(0xFFD0D5DD),
                    ),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox.square(
                            key: Key('categoryCreateProgress'),
                            dimension: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_isEditing ? '저장 중' : '생성 중'),
                        ],
                      )
                    : Text(
                        _isEditing ? '저장' : '생성',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNameChanged() {
    if (!mounted) return;
    setState(() => _saveFailed = false);
  }

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });

    Result<Category> result;
    try {
      result = await widget.save(
        CreateCategoryParams(
          name: _nameController.text.trim(),
          color: _selectedColor,
        ),
      );
    } catch (_) {
      result = fail(const CacheFailure('category create failed'));
    }
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(result.data!);
      return;
    }

    setState(() {
      _isSaving = false;
      _saveFailed = true;
    });
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF475467),
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.index,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final int index;
  final _CategoryColor option;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: option.name,
      button: true,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      onTap: enabled ? onSelected : null,
      child: ExcludeSemantics(
        child: InkWell(
          key: Key('categoryColorOption-$index'),
          onTap: enabled ? onSelected : null,
          customBorder: const CircleBorder(),
          child: Opacity(
            opacity: enabled ? 1 : .45,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(option.value),
                border: selected
                    ? Border.all(color: _navy, width: 3)
                    : Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 3),
                ],
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _CategoryColor {
  const _CategoryColor(this.name, this.value);

  final String name;
  final int value;
}

const _palette = [
  _CategoryColor('하늘색', 0xFF67C1DE),
  _CategoryColor('연두색', 0xFF9BDD55),
  _CategoryColor('노란색', 0xFFFFD24A),
  _CategoryColor('코랄색', 0xFFFF8A65),
  _CategoryColor('주황색', 0xFFFFA629),
  _CategoryColor('분홍색', 0xFFE76F8A),
  _CategoryColor('보라색', 0xFF7C3AED),
  _CategoryColor('네이비', 0xFF2E4175),
];

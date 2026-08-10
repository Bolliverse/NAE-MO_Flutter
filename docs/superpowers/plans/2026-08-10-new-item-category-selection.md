# New Item Category Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 통합 새 항목 화면에서 저장된 카테고리를 조회하고 일정/Todo에 공통으로 선택할 수 있게 한다.

**Architecture:** `NewItemCategoryInput`이 카테고리 조회 상태와 하단 선택창을 캡슐화하고, `NewItemPage`는 nullable 선택 ID만 보유한다. 조회는 기존 Riverpod `GetCategoriesUseCase`를 사용하되 테스트에서는 loader callback을 주입한다. 실제 저장과 카테고리 관리는 다음 PR로 남긴다.

**Tech Stack:** Flutter, Material, Riverpod, Dart, flutter_test

---

## 파일 구조와 PR 경계

- `docs/superpowers/specs/2026-08-10-new-item-category-selection-design.md`: 승인된 표시·상태 계약
- `docs/superpowers/plans/2026-08-10-new-item-category-selection.md`: TDD 구현 순서
- `lib/features/task/presentation/widgets/new_item_category_input.dart`: 조회 상태, 선택 행과 하단 선택창
- `test/features/task/presentation/pages/new_item_page_test.dart`: 상태와 화면 동작 회귀
- `lib/features/task/presentation/pages/new_item_page.dart`: 폼 배치와 선택 ID 보존
- `docs/design/evidence/pr-new-item-category-selection/new-item-category-selection-mobile.png`: 모바일 시각 증거

정확히 6개 파일만 변경하고 파일마다 별도 커밋한다. 실제 항목 저장,
카테고리 생성·수정·삭제, 알림과 반복은 포함하지 않는다. 이 세션에서는
별도 subagent 없이 계획을 순서대로 직접 실행한다.

### Task 1: 카테고리 상태와 화면 계약

**Files:**
- Modify: `test/features/task/presentation/pages/new_item_page_test.dart`

- [ ] **Step 1: 실패하는 상태 테스트 작성**

조회 성공 상태가 `sortOrder`, ID 순서로 목록을 정렬하고 선택 ID를 실제
카테고리로 해석하는지 검증한다.

```dart
test('category state sorts categories and resolves the selected id', () {
  final state = NewItemCategoryState.loaded([
    _category(id: 'b', sortOrder: 2),
    _category(id: 'c', sortOrder: 1),
    _category(id: 'a', sortOrder: 2),
  ]);

  expect(state.categories.map((item) => item.id), ['c', 'a', 'b']);
  expect(state.categoryFor('a')?.id, 'a');
  expect(state.categoryFor('missing'), isNull);
});
```

- [ ] **Step 2: 실패하는 위젯 테스트 작성**

결정적인 loader를 주입해 아래 계약을 추가한다.

```dart
await _pump(tester, categoryLoader: () async => success(categories));
await tester.pumpAndSettle();
await tester.tap(find.byKey(const Key('newItemCategoryButton')));
await tester.pumpAndSettle();
await tester.tap(find.byKey(const Key('newItemCategory-work')));
await tester.pumpAndSettle();
expect(find.text('연구'), findsOneWidget);
```

- 로딩 중에는 `카테고리 불러오는 중`과 비활성 선택 행을 표시한다.
- 빈 목록에서도 선택창에 `카테고리 없음` 하나를 표시한다.
- 실패 시 `카테고리를 불러오지 못했습니다.`와 `다시 시도`를 표시한다.
- 재시도 성공 후 선택창을 열 수 있다.
- 선택 후 일정/Todo를 전환해도 선택값이 유지된다.
- 선택 행 semantics는 `카테고리, 연구`처럼 현재 값을 포함한다.

- [ ] **Step 3: RED 확인**

Run: `flutter test test/features/task/presentation/pages/new_item_page_test.dart`

Expected: `NewItemCategoryState`, `NewItemCategoryLoader`와 카테고리 UI key가 없어 실패한다.

- [ ] **Step 4: 테스트 파일 커밋**

```powershell
git add -- test/features/task/presentation/pages/new_item_page_test.dart
git commit -m "test: specify new item category selection"
```

### Task 2: 조회 상태와 카테고리 선택 widget

**Files:**
- Create: `lib/features/task/presentation/widgets/new_item_category_input.dart`

- [ ] **Step 1: immutable 조회 상태 구현**

```dart
enum NewItemCategoryStatus { loading, loaded, failed }

@immutable
class NewItemCategoryState {
  const NewItemCategoryState._({
    required this.status,
    this.categories = const [],
  });

  const NewItemCategoryState.loading()
      : this._(status: NewItemCategoryStatus.loading);

  factory NewItemCategoryState.loaded(List<Category> categories) {
    final sorted = [...categories]
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return NewItemCategoryState._(
      status: NewItemCategoryStatus.loaded,
      categories: List.unmodifiable(sorted),
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
```

- [ ] **Step 2: loader와 조회 상태 전환 구현**

`NewItemCategoryInput`은 optional loader가 없으면
`ref.read(getCategoriesUseCaseProvider).call()`을 사용한다. `initState`에서
한 번 조회하고 실패 시 failed 상태로 바꾸며, `다시 시도`가 같은 `_load`를
호출한다. dispose 뒤 결과는 반영하지 않는다.

```dart
typedef NewItemCategoryLoader = Future<Result<List<Category>>> Function();

Future<void> _load() async {
  setState(() => _state = const NewItemCategoryState.loading());
  final loader = widget.loader ??
      () => ref.read(getCategoriesUseCaseProvider).call();
  final result = await loader();
  if (!mounted) return;
  setState(() {
    _state = result.isSuccess
        ? NewItemCategoryState.loaded(result.data!)
        : const NewItemCategoryState.failed();
  });
}
```

- [ ] **Step 3: 선택 행과 하단 선택창 구현**

loaded 상태에서는 `카테고리 없음` 또는 선택된 색상 점과 이름을 한 줄로
표시한다. 선택 행을 누르면 흰색 하단 선택창을 열고, `카테고리 없음`과
정렬된 카테고리를 최소 높이 52px의 custom row로 표시한다. 각 row에는
색상 점, 이름, 현재값 체크 표시와 selected semantics를 제공한다.

```dart
await showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.white,
  isScrollControlled: true,
  builder: (sheetContext) => _CategorySheet(
    categories: _state.categories,
    selectedId: widget.selectedId,
    onSelected: (id) {
      widget.onSelected(id);
      Navigator.of(sheetContext).pop();
    },
  ),
);
```

- [ ] **Step 4: 단독 상태 테스트 확인**

Run: `flutter test test/features/task/presentation/pages/new_item_page_test.dart`

Expected: 상태 정렬 테스트는 통과하고 `NewItemPage.categoryLoader`와 폼 배치가 없어 위젯 테스트는 계속 실패한다.

- [ ] **Step 5: widget 파일 커밋**

```powershell
git add -- lib/features/task/presentation/widgets/new_item_category_input.dart
git commit -m "feat: add new item category input"
```

### Task 3: 통합 새 항목 폼 연결

**Files:**
- Modify: `lib/features/task/presentation/pages/new_item_page.dart`

- [ ] **Step 1: 선택 상태와 테스트 주입점 추가**

```dart
class NewItemPage extends StatefulWidget {
  const NewItemPage({
    required this.selectedDate,
    required this.onClose,
    this.timePicker,
    this.categoryLoader,
    super.key,
  });

  final NewItemCategoryLoader? categoryLoader;
}

class _NewItemPageState extends State<NewItemPage> {
  String? _selectedCategoryId;
}
```

- [ ] **Step 2: 제목과 시간 사이에 입력 배치**

```dart
const SizedBox(height: 28),
const _FieldLabel('카테고리'),
const SizedBox(height: 8),
NewItemCategoryInput(
  loader: widget.categoryLoader,
  selectedId: _selectedCategoryId,
  onSelected: (id) => setState(() => _selectedCategoryId = id),
),
const SizedBox(height: 28),
const _FieldLabel('시간'),
```

- [ ] **Step 3: GREEN 확인**

Run: `flutter test test/features/task/presentation/pages/new_item_page_test.dart`

Expected: 정렬, 로딩, 빈 목록, 실패·재시도, 선택·보존, 접근성과 기존 시간 입력 테스트가 모두 통과한다.

- [ ] **Step 4: 페이지 파일 커밋**

```powershell
git add -- lib/features/task/presentation/pages/new_item_page.dart
git commit -m "feat: connect category selection to new item form"
```

### Task 4: 전체 검증과 시각 증거

**Files:**
- Create: `docs/design/evidence/pr-new-item-category-selection/new-item-category-selection-mobile.png`

- [ ] **Step 1: 정적·전체 검증**

Run: `dart format --output=none --set-exit-if-changed lib test`

Run: `flutter analyze --no-fatal-infos`

Run: `flutter test --reporter compact`

Run: `git diff --check origin/main...HEAD`

Expected: 새 오류·경고 없이 전체 테스트 통과.

- [ ] **Step 2: 모바일 웹 확인**

임시 visual harness에서 연구, 개인, 건강 카테고리를 반환하도록 loader를
주입하고 Flutter web을 실행한다. 390x844에서 `연구`가 선택된 하단 선택창을
캡처한다. 제목, 카테고리 행, 모든 카테고리 이름과 색상, 현재값 체크가
잘리지 않고 콘솔 오류가 없어야 한다.

- [ ] **Step 3: 임시 파일 정리와 증거 커밋**

임시 harness, build 출력과 서버를 제거하고 이미지 한 파일만 커밋한다.

```powershell
git add -- docs/design/evidence/pr-new-item-category-selection/new-item-category-selection-mobile.png
git commit -m "docs: add new item category selection evidence"
```

- [ ] **Step 4: PR 크기 확인과 게시**

변경 파일이 정확히 6개이고 모든 커밋이 한 파일만 수정하는지 확인한다.
`codex/new-item-category-selection`을 push하고 `main` 대상 Draft PR 하나를
만든다. PR 본문에는 범위 제외 항목, 검증 결과와 모바일 이미지를 포함한다.

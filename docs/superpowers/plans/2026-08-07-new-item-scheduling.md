# New Item Scheduling Inputs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 통합 새 항목 화면에 일정/Todo별 시간 형태와 시작·종료 시각 입력, 범위 검증을 추가한다.

**Architecture:** 화면과 분리된 immutable `NewItemScheduleDraft`가 종류별 시간 형태와 시각을 보존하고 오류를 계산한다. `NewItemPage`는 draft를 소유하며 네이티브 `showTimePicker` 결과만 상태에 반영한다. 저장과 도메인 변환은 다음 PR로 남긴다.

**Tech Stack:** Flutter, Material, Dart, flutter_test

---

## 파일 구조와 PR 경계

- `docs/superpowers/specs/2026-08-07-new-item-scheduling-design.md`: 승인된 화면·검증 계약
- `docs/superpowers/plans/2026-08-07-new-item-scheduling.md`: TDD 구현 순서
- `lib/features/task/presentation/states/new_item_schedule_draft.dart`: 순수 입력 상태와 오류 계산
- `test/features/task/presentation/states/new_item_schedule_draft_test.dart`: 상태 계약
- `lib/features/task/presentation/pages/new_item_page.dart`: 시간 형태와 선택 UI
- `test/features/task/presentation/pages/new_item_page_test.dart`: 화면 동작과 접근성 회귀
- `docs/design/evidence/pr-new-item-scheduling/new-item-scheduling-mobile.png`: 모바일 시각 증거

정확히 7개 파일만 변경한다. 실제 저장, 카테고리, 알림, 반복은 포함하지 않는다.

### Task 1: 시간 입력 상태

**Files:**
- Create: `test/features/task/presentation/states/new_item_schedule_draft_test.dart`
- Create: `lib/features/task/presentation/states/new_item_schedule_draft.dart`

- [ ] **Step 1: 실패하는 상태 테스트 작성**

일정은 시간 지정, Todo는 시간 없음으로 시작하고 종류별 형태를 독립적으로 보존하는지 검증한다. 시작 `10:00`, 종료 `09:30` 또는 `10:00`은 오류이며 `10:30`은 정상이어야 한다.

```dart
expect(const NewItemScheduleDraft().activeMode, NewItemTimeMode.timed);
expect(const NewItemScheduleDraft(kind: NewItemKind.todo).activeMode,
    NewItemTimeMode.untimed);
expect(invalid.timeRangeError, '종료 시간은 시작 시간보다 늦어야 합니다.');
```

- [ ] **Step 2: RED 확인**

Run: `flutter test test/features/task/presentation/states/new_item_schedule_draft_test.dart`

Expected: 상태 파일 또는 타입을 찾지 못해 실패한다.

- [ ] **Step 3: 최소 상태 구현**

`NewItemKind`, `NewItemTimeMode`, `NewItemScheduleDraft`를 정의한다. draft는 `kind`, `eventMode`, `todoMode`, nullable `startTime`, `endTime`을 가지며 `withKind`, `withMode`, `withStartTime`, `withEndTime`으로 새 값을 반환한다. `activeMode`, `showsTimeFields`, `timeRangeError`는 현재 종류를 기준으로 계산한다.

- [ ] **Step 4: GREEN 확인**

Run: `flutter test test/features/task/presentation/states/new_item_schedule_draft_test.dart`

Expected: 모든 상태 테스트 통과.

- [ ] **Step 5: 파일별 커밋**

테스트 파일과 구현 파일을 각각 별도 커밋한다.

### Task 2: 시간 형태와 선택 UI

**Files:**
- Modify: `test/features/task/presentation/pages/new_item_page_test.dart`
- Modify: `lib/features/task/presentation/pages/new_item_page.dart`

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

일정의 `시간 지정/종일`, Todo의 `시간 없음/시간 지정`을 검증한다. 주입한 time picker가 반환한 시작·종료 값이 표시되고, 잘못된 범위에서 오류 문구가 나타나며 정상 종료 시각으로 바꾸면 사라져야 한다. 종류를 바꿨다가 돌아와도 시각이 유지되어야 한다.

```dart
await tester.tap(find.byKey(const Key('newItemStartTimeButton')));
await tester.pump();
expect(find.text('오전 10:00'), findsOneWidget);
expect(find.text('종료 시간은 시작 시간보다 늦어야 합니다.'), findsOneWidget);
```

- [ ] **Step 2: RED 확인**

Run: `flutter test test/features/task/presentation/pages/new_item_page_test.dart`

Expected: 새 시간 형태와 버튼 key를 찾지 못해 실패한다.

- [ ] **Step 3: 최소 화면 구현**

기존 종류 enum을 상태 파일에서 가져오고 draft로 종류를 전환한다. 시간 형태 선택기와 시작·종료 버튼을 추가하며, 기본 동작은 `showTimePicker`를 사용한다. 테스트에서는 optional picker callback을 주입한다. 저장 버튼은 비활성 상태로 유지한다.

- [ ] **Step 4: GREEN과 반응형 확인**

Run: `flutter test test/features/task/presentation/pages/new_item_page_test.dart`

Expected: 시간 입력, 오류, 보존, 390px 큰 글자 테스트 통과.

- [ ] **Step 5: 파일별 커밋**

테스트 파일과 구현 파일을 각각 별도 커밋한다.

### Task 3: 전체 검증과 시각 증거

**Files:**
- Create: `docs/design/evidence/pr-new-item-scheduling/new-item-scheduling-mobile.png`

- [ ] **Step 1: 정적·전체 검증**

Run: `dart format --output=none --set-exit-if-changed lib test`

Run: `flutter analyze --no-fatal-infos`

Run: `flutter test`

Run: `git diff --check origin/main...HEAD`

Expected: 새 오류·경고 없이 전체 테스트 통과.

- [ ] **Step 2: 모바일 웹 확인**

Flutter web을 임시 디렉터리에 빌드·실행하고 390x844에서 시간 지정 일정 화면을 확인한다. 콘솔 오류가 없어야 하며 이미지에는 날짜, 종류, 제목, 시간 형태, 시작·종료 입력이 모두 보여야 한다.

- [ ] **Step 3: 증거 커밋과 PR 크기 확인**

이미지 한 파일을 별도 커밋하고 변경 파일이 정확히 7개인지 확인한다. 임시 서버와 임시 파일을 제거한다.

- [ ] **Step 4: 게시**

`codex/new-item-scheduling`을 push하고 `main` 대상 Draft PR 하나를 생성한다. PR 본문에 범위 제외 항목, 검증 결과, 모바일 이미지를 포함한다.

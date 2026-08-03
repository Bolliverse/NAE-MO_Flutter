# Daily Split Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 Today 데이터 위에 공유 날짜 헤더와 82:18 Calendar/Todo 분할 셸을 만들고 가로 전환과 하나의 세로 시간 스크롤을 제공한다.

**Architecture:** `DailySplitScaffold`가 패널 진행도와 스냅 애니메이션을 소유하고, 고정 행과 시간 행을 같은 너비로 배치한다. `TodayPage`는 기존 `TodayViewModel` 데이터를 Calendar와 Todo로 필터링해 셸의 builder에 전달하며 저장 계층은 변경하지 않는다.

**Tech Stack:** Flutter, Dart, Riverpod, flutter_test

---

## PR 경계

이 계획은 `codex/today-page`를 base로 하는 첫 번째 스택 PR만 구현한다. 변경 파일은
코드·문서 7개와 리뷰 증거 이미지 2개, 총 9개로 제한한다.

- `docs/superpowers/plans/2026-08-03-daily-split-shell.md`
- `test/features/calendar/presentation/widgets/today_date_header_test.dart`
- `lib/features/calendar/presentation/widgets/today_date_header.dart`
- `test/features/calendar/presentation/widgets/daily_split_scaffold_test.dart`
- `lib/features/calendar/presentation/widgets/daily_split_scaffold.dart`
- `test/features/calendar/presentation/pages/today_page_test.dart`
- `lib/features/calendar/presentation/pages/today_page.dart`
- `docs/design/evidence/pr-daily-split-shell/daily-split-mobile.png`
- `docs/design/evidence/pr-daily-split-shell/daily-split-web.png`

좁은 패널의 실제 카테고리 미리보기, `+N`, 최종 시간 카드, FAB는 후속 스택 PR에
남긴다. 첫 PR에서는 좁은 pane builder를 비워 두지 않고 의미 없는 텍스트 대신
중립색 preview surface로 렌더링한다.

### Task 1: 공유 날짜 헤더

**Files:**
- Modify: `test/features/calendar/presentation/widgets/today_date_header_test.dart`
- Modify: `lib/features/calendar/presentation/widgets/today_date_header.dart`

- [ ] **Step 1: 단순 날짜 헤더의 실패 테스트 작성**

기존 7일 strip 기대를 제거하고 다음 계약을 검증한다.

```dart
testWidgets('shows one centered shared date with previous and next controls',
    (tester) async {
  await _pumpHeader(tester);

  expect(find.text('7/29'), findsOneWidget);
  expect(find.byKey(const Key('todayPreviousDate')), findsOneWidget);
  expect(find.byKey(const Key('todayNextDate')), findsOneWidget);
  expect(find.byKey(const Key('todayGoToToday')), findsNothing);
});
```

이전/다음 callback, 48dp 터치 영역, 큰 글자 390px 무오버플로도 같은 파일에서
검증한다.

- [ ] **Step 2: 헤더 테스트가 기존 구현에서 실패하는지 확인**

Run:

```powershell
flutter test test/features/calendar/presentation/widgets/today_date_header_test.dart
```

Expected: `7/29`를 찾지 못하고 기존 7일 strip이 남아 있어 FAIL.

- [ ] **Step 3: 테스트 파일만 커밋**

```powershell
git add test/features/calendar/presentation/widgets/today_date_header_test.dart
git commit -m "test: define shared daily date header"
```

- [ ] **Step 4: 단순 공유 날짜 헤더 구현**

`TodayDateHeader`의 public API를 아래처럼 축소한다.

```dart
const TodayDateHeader({
  super.key,
  required this.selectedDate,
  required this.onPrevious,
  required this.onNext,
});
```

본문은 흰 배경의 `Row`로 만들고 가운데 날짜를 밑줄과 함께 표시한다.

```dart
Row(
  children: [
    IconButton(key: const Key('todayPreviousDate'), ...),
    Expanded(
      child: Center(
        child: Text(
          DateFormat('M/d').format(selectedDate),
          key: const Key('todaySharedDate'),
          style: theme.textTheme.headlineMedium?.copyWith(
            decoration: TextDecoration.underline,
            decorationThickness: 1,
          ),
        ),
      ),
    ),
    IconButton(key: const Key('todayNextDate'), ...),
  ],
)
```

- [ ] **Step 5: 헤더 테스트 통과 확인**

Run:

```powershell
flutter test test/features/calendar/presentation/widgets/today_date_header_test.dart
```

Expected: PASS.

- [ ] **Step 6: 헤더 구현 파일만 커밋**

```powershell
git add lib/features/calendar/presentation/widgets/today_date_header.dart
git commit -m "feat: simplify shared daily date header"
```

### Task 2: 분할 셸과 동기화된 시간 영역

**Files:**
- Create: `test/features/calendar/presentation/widgets/daily_split_scaffold_test.dart`
- Create: `lib/features/calendar/presentation/widgets/daily_split_scaffold.dart`

- [ ] **Step 1: 분할 셸의 실패 테스트 작성**

테스트 fixture는 고정 높이 header, pinned pane, 1200px timeline pane을 제공한다.
아래 동작을 각각 검증한다.

```dart
expect(calendarWidth / availableWidth, closeTo(.82, .02));
expect(todoWidth / availableWidth, closeTo(.18, .02));

await tester.drag(
  find.byKey(const Key('dailySplitGestureArea')),
  const Offset(-260, 0),
);
await tester.pumpAndSettle();
expect(todoWidth / availableWidth, closeTo(.82, .02));

await tester.tap(find.byKey(const Key('dailyCalendarCompactTapTarget')));
await tester.pumpAndSettle();
expect(calendarWidth / availableWidth, closeTo(.82, .02));
```

시간 영역을 세로로 드래그한 뒤 header와 pinned 행의 y 좌표는 유지되고 두 timeline
pane의 동일한 marker가 같은 y 좌표로 이동하는지도 검증한다.

- [ ] **Step 2: 새 셸 테스트가 컴파일 실패하는지 확인**

Run:

```powershell
flutter test test/features/calendar/presentation/widgets/daily_split_scaffold_test.dart
```

Expected: `daily_split_scaffold.dart`가 없어 FAIL.

- [ ] **Step 3: 셸 테스트 파일만 커밋**

```powershell
git add test/features/calendar/presentation/widgets/daily_split_scaffold_test.dart
git commit -m "test: define daily split shell interactions"
```

- [ ] **Step 4: DailySplitScaffold 구현**

다음 public types를 만든다.

```dart
enum DailyPane { calendar, todo }

class DailyPaneLayout {
  const DailyPaneLayout({required this.fraction});
  final double fraction;
  bool get isCompact => fraction < .5;
}

typedef DailyPaneBuilder = Widget Function(
  BuildContext context,
  DailyPaneLayout layout,
);
```

`DailySplitScaffold`는 `header`, Calendar/Todo의 pinned builder와 timeline builder,
`initialPane`, `onPaneChanged`를 받는다. 내부 진행도 `0`은 Calendar, `1`은 Todo이며
Calendar fraction은 아래 식으로 계산한다.

```dart
double get calendarFraction =>
    lerpDouble(.82, .18, _progress) ?? .82;
double get todoFraction => 1 - calendarFraction;
```

가로 drag delta를 가용 너비로 나눠 `_progress`를 0~1로 제한한다. drag end에서
절대 속도가 300px/s 이상이면 속도 방향을, 아니면 진행도 0.5를 기준으로 목표 pane을
결정하고 220ms `Curves.easeOutCubic` 애니메이션으로 스냅한다.

날짜 header 아래에는 같은 `_progress`를 사용하는 두 `_PaneRow`를 둔다. 첫 행은
pinned builder, 둘째 행은 하나의 `SingleChildScrollView` 안에서 timeline builder를
배치한다. 이 구조로 별도 scroll 동기화 코드 없이 두 패널의 시간 위치가 같아진다.

- [ ] **Step 5: 셸 테스트 통과 확인**

Run:

```powershell
flutter test test/features/calendar/presentation/widgets/daily_split_scaffold_test.dart
```

Expected: PASS.

- [ ] **Step 6: 셸 구현 파일만 커밋**

```powershell
git add lib/features/calendar/presentation/widgets/daily_split_scaffold.dart
git commit -m "feat: add synchronized daily split shell"
```

### Task 3: Today 화면 연결

**Files:**
- Modify: `test/features/calendar/presentation/pages/today_page_test.dart`
- Modify: `lib/features/calendar/presentation/pages/today_page.dart`

- [ ] **Step 1: Today 연결 실패 테스트 작성**

기존 한 열 section 순서 테스트를 교체하고 아래 계약을 검증한다.

```dart
expect(find.byKey(const Key('dailySplitScaffold')), findsOneWidget);
expect(find.byKey(const Key('dailyCalendarPinned')), findsOneWidget);
expect(find.byKey(const Key('dailyTodoPinned')), findsOneWidget);
expect(find.byKey(const Key('dailyCalendarTimeline')), findsOneWidget);
expect(find.byKey(const Key('dailyTodoTimeline')), findsOneWidget);
```

fixture의 event 제목은 Calendar expanded pane에만, scheduled Todo 제목은 Todo pane을
확대한 뒤 그 pane에만 나타나는지 검증한다. 날짜 이동, 로딩, 오류, Todo 토글의 기존
테스트는 유지한다.

- [ ] **Step 2: 기존 TodayPage에서 실패하는지 확인**

Run:

```powershell
flutter test test/features/calendar/presentation/pages/today_page_test.dart
```

Expected: `dailySplitScaffold`를 찾지 못해 FAIL.

- [ ] **Step 3: Today page 테스트 파일만 커밋**

```powershell
git add test/features/calendar/presentation/pages/today_page_test.dart
git commit -m "test: define Today split shell integration"
```

- [ ] **Step 4: TodayPage를 DailySplitScaffold에 연결**

`TodayDateHeader`에는 이전/다음 callback만 전달한다. `_TodayContent`에서
`overview.timelineItems`를 종류별로 나눈다.

```dart
final calendarTimeline = overview.timelineItems
    .where((entry) => entry.task.isEvent)
    .toList(growable: false);
final todoTimeline = overview.timelineItems
    .where((entry) => entry.task.isTodo)
    .toList(growable: false);
```

expanded Calendar는 기존 `TodayAllDaySection`과 event timeline을, expanded Todo는
기존 `TodayTodoSection`과 todo timeline을 사용한다. compact builder는 후속 PR의
카테고리 preview가 들어갈 고정 중립 surface만 반환하고 개별 항목 interaction을
노출하지 않는다.

- [ ] **Step 5: Today 관련 테스트 통과 확인**

Run:

```powershell
flutter test test/features/calendar/presentation/pages/today_page_test.dart
flutter test test/features/calendar/presentation/widgets
```

Expected: PASS.

- [ ] **Step 6: TodayPage 구현 파일만 커밋**

```powershell
git add lib/features/calendar/presentation/pages/today_page.dart
git commit -m "feat: connect Today to split daily shell"
```

### Task 4: 첫 PR 검증과 증거

**Files:**
- No source changes

- [ ] **Step 1: 형식과 정적 분석**

Run:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
```

Expected: 두 명령 모두 exit code 0.

- [ ] **Step 2: 전체 테스트**

Run:

```powershell
flutter test
```

Expected: 전체 PASS.

- [ ] **Step 3: PR 크기 확인**

Run:

```powershell
git diff --stat codex/today-page...HEAD
git diff --numstat codex/today-page...HEAD
```

Expected: 계획된 9개 파일 이내이며 총 변경 줄이 2K를 넘지 않음.

- [ ] **Step 4: Flutter web에서 모바일·웹 화면 캡처**

앱 fixture 또는 인증된 개발 fixture로 390px와 1200px 화면을 렌더링한다. 캡처는
후속 content PR의 최종 증거와 혼동되지 않도록 PR 본문에 `interaction shell`임을
명시한다. 이미지는 위에 고정한 evidence 경로에 저장하고 파일당 별도 커밋을 사용한다.

- [ ] **Step 5: 원격 push와 스택 PR 생성**

```powershell
git push -u origin codex/daily-split-shell
gh pr create --base codex/today-page --head codex/daily-split-shell
```

PR 본문에는 PR #7 의존성, 첫 단계 범위, 후속 content/FAB PR 경계, 검증 명령,
화면 캡처를 포함한다.

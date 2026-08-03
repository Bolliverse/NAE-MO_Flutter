# Daily Todo Content Implementation Plan

**Goal:** Daily 분할 셸의 Todo 패널을 시간 없는 고정 목록, 시간축 목록, 좁은
카테고리 색상 미리보기로 교체한다.

**Architecture:** 새 `daily_todo_pane.dart`가 Todo의 넓은/좁은 표현과 체크
상호작용을 담당한다. `TodayPage`는 overdue, untimed, completed Todo를 고정/시간
영역으로 다시 조합하고 기존 `TodayViewModel.toggleTodo`를 그대로 연결한다.

## PR 경계

이 PR은 `codex/daily-split-content`를 base로 한다. Calendar 표현, 상단 메뉴,
FAB와 설정 흐름은 수정하지 않는다. 변경 파일은 아래 7개, 1.5K 변경 줄 이내다.

- `docs/superpowers/plans/2026-08-03-daily-todo-content.md`
- `test/features/calendar/presentation/widgets/daily_todo_pane_test.dart`
- `lib/features/calendar/presentation/widgets/daily_todo_pane.dart`
- `test/features/calendar/presentation/pages/today_page_test.dart`
- `lib/features/calendar/presentation/pages/today_page.dart`
- `docs/design/evidence/pr-daily-todo-content/todo-mobile.png`
- `docs/design/evidence/pr-daily-todo-content/todo-web.png`

## 시각 규칙

- 흰 배경과 얇은 중립색 구분선을 유지한다.
- 넓은 Todo는 Material `Checkbox`나 색상 카드 대신 카테고리 색상의 작은 정사각형
  체크 컨트롤과 텍스트만 표시한다.
- 시간 없는 Todo와 overdue Todo는 날짜 아래 고정 영역에 둔다.
- 시간 지정 Todo는 Calendar와 같은 0–24시 시간축의 실제 시작 시각에 둔다.
- completed Todo는 원래 `hasTime` 값에 따라 고정 영역 또는 시간축에 되돌려 놓고
  체크와 취소선을 표시한다.
- 좁은 패널은 텍스트 없이 카테고리 색상, 체크 상태, 실제 시간 위치만 전달한다.
- 좁은 영역의 표시 한도를 넘는 항목은 `+N`으로 요약한다.
- 빈 날짜에는 안내 카드와 `0` 배지를 표시하지 않는다.

## TDD 순서

### 1. Todo pane 위젯 테스트

- 넓은 고정 목록이 untimed/overdue/completed 상태와 카테고리 색을 표시한다.
- 체크 컨트롤은 48dp 터치 영역과 하나의 checked semantic action을 제공한다.
- pending Todo는 비활성화된다.
- 좁은 고정 목록은 최대 3개 색상 표식과 `+N`만 표시한다.
- 넓은 시간축은 실제 시작 시각, 제목, 시간, 완료 상태를 표시한다.
- 좁은 시간축은 실제 위치의 색상 표식과 겹침 `+N`을 표시한다.
- 빈 날짜와 큰 글자/390px에서 overflow가 없다.

테스트 파일만 먼저 커밋하고 실패를 확인한다.

### 2. Todo pane 구현

- `DailyTodoPinned`과 `DailyTodoTimeline`을 구현한다.
- Calendar의 hour extent/height 상수를 공유해 두 패널의 시간선을 정렬한다.
- 체크 성공/실패 상태는 위젯 안에 복제하지 않고 callback/pending 값만 반영한다.

구현 파일만 커밋하고 위젯 테스트를 통과시킨다.

### 3. TodayPage 연결

- 고정 Todo: overdue + untimed + completed 중 `hasTime == false`
- 시간 Todo: active timed + completed 중 `hasTime == true`
- 기존 `TodayOverdueSection`, `TodayTodoSection`, Todo용 `TodayTimelineSection`을 교체한다.
- optimistic toggle, 날짜 이동 후 실패 무시, SnackBar 회귀 테스트는 유지한다.
- Calendar/Todo 전환 후 새 expanded/compact key를 page 테스트에서 검증한다.

page 테스트와 구현을 각각 한 파일씩 커밋한다.

### 4. 검증과 증거

- 변경 Dart format/analyze
- 전체 `flutter test`
- Flutter web 390px/1200px에서 Todo expanded와 Calendar active 시 Todo compact 확인
- 브라우저 rendering error 확인
- 모바일·웹 이미지를 각각 한 파일씩 커밋
- 7개 파일과 변경 줄 경계를 확인해 스택 PR 생성


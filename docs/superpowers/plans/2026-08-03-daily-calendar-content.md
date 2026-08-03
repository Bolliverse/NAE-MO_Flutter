# Daily Calendar Content Implementation Plan

**Goal:** Daily 분할 셸의 Calendar 패널만 사용자의 스케치에 가까운 종일 막대,
시간 눈금, 일정 블록, 좁은 색상 미리보기로 교체한다.

**Architecture:** 새 `daily_calendar_pane.dart`가 Calendar 데이터의 넓은 표현과
좁은 표현을 함께 소유한다. `TodayPage`는 event만 필터링해 전달하고,
`DailySplitScaffold`의 너비 전환과 공용 세로 스크롤은 그대로 유지한다.

## PR 경계

이 PR은 `codex/daily-split-shell`을 base로 한다. Todo 표현, 완료 토글 UI, FAB와
설정 흐름은 수정하지 않는다. 변경 파일은 아래 7개, 1.5K 변경 줄 이내를 목표로 한다.

- `docs/superpowers/plans/2026-08-03-daily-calendar-content.md`
- `test/features/calendar/presentation/widgets/daily_calendar_pane_test.dart`
- `lib/features/calendar/presentation/widgets/daily_calendar_pane.dart`
- `test/features/calendar/presentation/pages/today_page_test.dart`
- `lib/features/calendar/presentation/pages/today_page.dart`
- `docs/design/evidence/pr-daily-calendar-content/calendar-mobile.png`
- `docs/design/evidence/pr-daily-calendar-content/calendar-web.png`

## 시각 규칙

- 흰 배경과 얇은 중립색 시간선을 사용한다.
- 종일 일정은 카테고리 색 자체를 사용하는 낮은 가로 막대로 표시한다.
- 시간 일정은 시작 시각에 맞춰 배치하고 실제 지속 시간에 비례한 색상 블록으로 표시한다.
- 넓은 블록에는 제목과 시간 범위만 표시하며 Material 카드 그림자를 사용하지 않는다.
- 좁은 패널은 텍스트 없이 같은 색과 세로 위치를 유지한다.
- 좁은 고정 영역은 최대 3개 미리보기를 겹쳐 표시하고 나머지는 `+N`으로 표시한다.
- 좁은 시간대에서 동시에 겹치는 항목도 최대 2개 색상 표식과 `+N`으로 요약한다.
- 일정이 없으면 안내 카드를 넣지 않고 시간선만 남긴다.

## TDD 순서

### 1. Calendar pane 위젯 테스트

- 넓은 종일 막대가 제목과 카테고리 색을 표시한다.
- 좁은 종일 요약은 텍스트를 숨기고 3개 초과분을 `+N`으로 표시한다.
- 넓은 시간축은 시간 눈금과 시작/종료 시각에 맞는 블록 위치·높이를 갖는다.
- 좁은 시간축은 동일한 세로 위치의 색상 표식과 동시 항목 `+N`을 표시한다.
- 빈 날짜는 시간선만 표시하고 `0` 배지는 표시하지 않는다.
- 390px와 큰 글자에서도 overflow가 없다.

테스트 파일만 먼저 커밋하고 실패를 확인한다.

### 2. Calendar pane 구현

- 고정 영역용 `DailyCalendarPinned`을 구현한다.
- 시간 영역용 `DailyCalendarTimeline`을 구현한다.
- 시간축은 0시부터 24시까지 고정된 hour extent로 그려 두 패널 공용 스크롤과 정렬한다.
- 카테고리가 없으면 중립색을 사용한다.

구현 파일만 커밋하고 위젯 테스트를 통과시킨다.

### 3. TodayPage 연결

- 기존 `TodayAllDaySection`과 Calendar용 `TodayTimelineSection`을 새 위젯으로 교체한다.
- Todo 쪽 기존 위젯과 상태 처리는 그대로 둔다.
- Calendar가 좁아져도 해당 pane widget이 색상 미리보기를 렌더링하는지 page 테스트에 추가한다.

page 테스트와 구현은 각각 한 파일씩 커밋한다.

### 4. 검증과 화면 증거

- 변경 Dart 파일 format
- 변경 Dart 파일 analyze
- 전체 `flutter test`
- Flutter web 390px/1200px 렌더링 및 브라우저 예외 확인
- 모바일·웹 이미지를 각각 한 파일씩 커밋
- base 대비 파일 수와 변경 줄 확인 후 스택 PR 생성


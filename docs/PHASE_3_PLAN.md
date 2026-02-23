# Phase 3 — Day View 상세 개발 계획

> 기준 문서: [PLAN.md](PLAN.md), [DEV_SPEC.md](DEV_SPEC.md)
> 최종 업데이트: 2026-02-23
>
> **구현 원칙**: 각 스텝은 독립적으로 동작 가능해야 하며, 이전 스텝이 완료된 후 다음 스텝으로 진행한다.

---

## 전체 스텝 요약

| 스텝 | 이름 | 핵심 결과물 | 상태 |
|------|------|------------|------|
| 3-A | State & ViewModel 기반 | DayViewState, TaskDockState, ViewModels | ⬜ |
| 3-B | Timeline 그리드 렌더링 | CustomPainter, 시간 라벨, 스크롤 | ⬜ |
| 3-C | TaskBlock 정적 배치 | TaskBlock 위젯, 오버랩 처리 | ⬜ |
| 3-D | TaskDock 목록 렌더링 | TaskDockItem, 섹션 구분 | ⬜ |
| 3-E | 드래그 시스템 | Dock→Timeline 드래그, 스냅 | ⬜ |
| 3-F | 블록 리사이즈 | 하단 핸들 드래그, 시간 수정 | ⬜ |
| 3-G | 완료 토글 & 완료 섹션 | 체크박스, Completed 접기 | ⬜ |
| 3-H | AllDayEventBar | 종일 이벤트 표시 | ⬜ |
| 3-I | QuickAddInput | 하단 빠른 입력 | ⬜ |

---

## 3-A. State & ViewModel 기반 구성

> 비즈니스 로직의 진입점. 이후 모든 스텝이 이 기반 위에 구현된다.

### 생성 파일

```
lib/features/calendar/presentation/
├── states/
│   ├── day_view_state.dart          ← freezed sealed class
│   └── task_dock_state.dart         ← freezed sealed class
└── viewmodels/
    ├── day_view_viewmodel.dart       ← @riverpod class
    └── task_dock_viewmodel.dart      ← @riverpod class
```

### DayViewState

```dart
// states/day_view_state.dart
@freezed
sealed class DayViewState with _$DayViewState {
  const factory DayViewState.loading() = DayViewLoading;
  const factory DayViewState.data({
    required List<Task> scheduledTasks,   // hasTime == true
    required DateTime date,
  }) = DayViewData;
  const factory DayViewState.error(Failure failure) = DayViewError;
}
```

### DayViewViewModel

```dart
// viewmodels/day_view_viewmodel.dart
@riverpod
class DayViewViewModel extends _$DayViewViewModel {
  @override
  Future<DayViewState> build() async { ... }

  // 내부 메서드 (드래그, 리사이즈에서 호출)
  Future<void> scheduleTask(String taskId, DateTime start, DateTime end);
  Future<void> resizeTask(String taskId, DateTime newEnd);
  Future<void> moveTask(String taskId, DateTime newStart, DateTime newEnd);
}
```

### TaskDockState

```dart
// states/task_dock_state.dart
@freezed
sealed class TaskDockState with _$TaskDockState {
  const factory TaskDockState.loading() = TaskDockLoading;
  const factory TaskDockState.data({
    required List<Task> unscheduledTasks,
    required List<Task> completedTasks,
    @Default(false) bool isCompletedExpanded,
  }) = TaskDockData;
  const factory TaskDockState.error(Failure failure) = TaskDockError;
}
```

### TaskDockViewModel

```dart
// viewmodels/task_dock_viewmodel.dart
@riverpod
class TaskDockViewModel extends _$TaskDockViewModel {
  @override
  Future<TaskDockState> build();

  Future<void> toggleComplete(String taskId);
  void toggleCompletedSection();  // 완료 섹션 펼치기/접기
}
```

### DayViewPage 연결

기존 `day_view_page.dart`의 placeholder를 제거하고 ViewModel을 watch하는 구조로 교체한다.

```dart
// DayViewPage.build()
final dayState = ref.watch(dayViewViewModelProvider);
final dockState = ref.watch(taskDockViewModelProvider);

return Row(
  children: [
    TaskDock(state: dockState),
    const VerticalDivider(width: 1),
    Expanded(child: TimelineArea(state: dayState)),
  ],
);
```

---

## 3-B. Timeline 그리드 렌더링

> 데이터 없이 순수 UI만 완성한다. 이 스텝 완료 후 빈 타임라인이 보여야 한다.

### 생성 파일

```
lib/features/calendar/presentation/widgets/timeline/
├── timeline_area.dart           ← 스크롤 + Stack 컨테이너
├── timeline_grid_painter.dart   ← CustomPainter (그리드 선 + 시간 라벨)
└── timeline_constants.dart      ← 상수 (hourHeight 등)
```

### 상수 정의

```dart
// timeline_constants.dart
abstract class TimelineConstants {
  static const double hourHeight = 64.0;    // 1시간 = 64px
  static const double halfHourHeight = 32.0; // 30분 = 32px
  static const double timeLabeWidth = 48.0;  // 시간 라벨 영역 너비
  static const double totalHeight = hourHeight * 24; // 전체 높이 1536px
  static const int startHour = 0;            // 00:00 부터 시작
}
```

### TimelineGridPainter (CustomPainter)

```dart
// timeline_grid_painter.dart
class TimelineGridPainter extends CustomPainter {
  // 00:00 ~ 23:30 — 30분 단위 가로선
  // 정각: 실선 (진한 색)
  // 30분: 점선 (연한 색)
  // 좌측: 시간 텍스트 ("09:00", "09:30"...)

  @override
  void paint(Canvas canvas, Size size) { ... }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### TimelineArea 위젯

```dart
// timeline_area.dart
class TimelineArea extends StatefulWidget {
  final DayViewState state;
  // ...
}

// 내부 구조
SingleChildScrollView(
  controller: _scrollController,
  child: SizedBox(
    height: TimelineConstants.totalHeight,
    child: Stack(
      children: [
        // Layer 1: 그리드
        CustomPaint(painter: TimelineGridPainter()),
        // Layer 2: 현재 시간 표시선 (빨간선)
        _CurrentTimeLine(),
        // Layer 3: 이벤트 블록 (3-C에서 추가)
        // Layer 4: DragTarget (3-E에서 추가)
      ],
    ),
  ),
)
```

### 초기 스크롤 위치

```dart
// 앱 시작 시 현재 시간 위치로 자동 스크롤
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final now = DateTime.now();
    final offset = (now.hour - 1) * TimelineConstants.hourHeight;
    _scrollController.jumpTo(offset.clamp(0, double.infinity));
  });
}
```

---

## 3-C. TaskBlock 정적 배치

> DayViewViewModel에서 받은 scheduledTasks를 타임라인 위에 배치한다.

### 생성 파일

```
lib/features/calendar/presentation/widgets/timeline/
├── task_block.dart              ← 이벤트 블록 위젯
└── overlap_calculator.dart      ← 오버랩 레이아웃 계산 유틸
```

### 시간 → 픽셀 변환

```dart
// timeline_area.dart 내 헬퍼 (또는 별도 유틸)
double _timeToOffset(DateTime time) {
  return (time.hour + time.minute / 60.0) * TimelineConstants.hourHeight;
}

double _durationToHeight(DateTime start, DateTime end) {
  final minutes = end.difference(start).inMinutes;
  return (minutes / 60.0) * TimelineConstants.hourHeight;
}
```

### TaskBlock 위젯

```dart
// task_block.dart
class TaskBlock extends StatelessWidget {
  final Task task;
  final double top;       // 픽셀 위치
  final double height;    // 픽셀 높이
  final double left;      // 오버랩 시 좌측 offset
  final double width;     // 오버랩 시 너비 비율

  // 내부 구성:
  // - 카테고리 색상 좌측 바 (4px)
  // - 태스크 제목 + 시간 텍스트
  // - 완료 시 취소선 + 투명도 처리
  // - 하단 리사이즈 핸들 (3-F에서 활성화)
  // - onTap → EditTaskSheet (3-H/Phase 5에서 연결)
}
```

### 오버랩 처리

```dart
// overlap_calculator.dart
// 같은 시간대에 겹치는 블록들을 나란히 배치하기 위한 계산
class OverlapGroup {
  final List<Task> tasks;
  // → 각 Task에 (columnIndex, totalColumns) 부여
  // → TaskBlock.left = (columnIndex / totalColumns) * availableWidth
  // → TaskBlock.width = (1 / totalColumns) * availableWidth
}

List<OverlapGroup> calculateOverlaps(List<Task> tasks) { ... }
```

### Timeline Stack에 블록 추가

```dart
// timeline_area.dart — Stack 내부
...scheduledTasks.map((task) {
  return Positioned(
    top: _timeToOffset(task.startDateTime!),
    left: TimelineConstants.timeLabelWidth + block.left,
    width: block.width,
    height: _durationToHeight(task.startDateTime!, task.endDateTime!),
    child: TaskBlock(task: task, ...),
  );
}),
```

---

## 3-D. TaskDock 목록 렌더링

> 좌측 패널. 미배정 태스크 목록과 완료 섹션을 표시한다.

### 생성 파일

```
lib/features/calendar/presentation/widgets/task_dock/
├── task_dock.dart               ← 전체 Dock 컨테이너
└── task_dock_item.dart          ← 개별 태스크 아이템
```

### TaskDock 레이아웃

```dart
// task_dock.dart
// 고정 너비: 140px
Column(
  children: [
    // 헤더 ("미배정")
    Padding(..., child: Text('미배정', ...)),
    const Divider(),
    // 미배정 목록
    Expanded(
      child: ListView.builder(
        itemCount: unscheduledTasks.length,
        itemBuilder: (_, i) => TaskDockItem(task: unscheduledTasks[i]),
      ),
    ),
    // 완료 섹션 (3-G에서 완성)
    _CompletedSection(tasks: completedTasks, ...),
  ],
)
```

### TaskDockItem

```dart
// task_dock_item.dart
// - 카테고리 색상 점 (8px 원)
// - 태스크 제목
// - 완료 체크박스 (3-G에서 활성화)
// - Draggable (3-E에서 추가)
ListTile(
  dense: true,
  leading: _CategoryDot(color: task.categoryColor),
  title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
  trailing: _CompleteCheckbox(task: task),  // 3-G
)
```

---

## 3-E. 드래그 시스템 (Dock → Timeline)

> 이 스텝은 3가지 컴포넌트를 동시에 수정한다.

### 드래그 데이터 모델

```dart
// lib/features/calendar/presentation/models/task_drag_data.dart
class TaskDragData {
  final Task task;
  const TaskDragData({required this.task});
}
```

### Layer 1: Draggable (TaskDockItem)

```dart
// task_dock_item.dart 수정
Draggable<TaskDragData>(
  data: TaskDragData(task: task),
  // 드래그 중 고스트 위젯
  feedback: Material(
    elevation: 4,
    child: SizedBox(
      width: 120,
      child: _TaskDockItemContent(task: task),
    ),
  ),
  // 드래그 중 원래 위치 위젯 (반투명)
  childWhenDragging: Opacity(opacity: 0.3, child: _TaskDockItemContent(task: task)),
  child: _TaskDockItemContent(task: task),
)
```

### Layer 2: DragTarget (TimelineArea)

```dart
// timeline_area.dart — Stack에 DragTarget 추가
DragTarget<TaskDragData>(
  onWillAcceptWithDetails: (details) => true,
  onAcceptWithDetails: (details) {
    // 드롭 위치 → 시간 변환
    final renderBox = context.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(details.offset);
    final dropTime = _offsetToTime(localOffset.dy);

    // 30분 단위 스냅
    final snappedStart = _snap30min(dropTime);
    final snappedEnd = snappedStart.add(const Duration(minutes: 30));

    // UseCase 호출
    ref.read(dayViewViewModelProvider.notifier)
       .scheduleTask(details.data.task.id, snappedStart, snappedEnd);
  },
  builder: (context, candidateData, rejectedData) {
    return const SizedBox.expand(); // 투명 DragTarget
  },
)
```

### 30분 스냅 유틸

```dart
DateTime _snap30min(DateTime time) {
  final totalMinutes = time.hour * 60 + time.minute;
  final snapped = (totalMinutes / 30).round() * 30;
  return DateTime(time.year, time.month, time.day,
    snapped ~/ 60, snapped % 60);
}

DateTime _offsetToTime(double offset) {
  final totalMinutes = (offset / TimelineConstants.hourHeight * 60).round();
  final date = /* 현재 날짜 */;
  return DateTime(date.year, date.month, date.day,
    totalMinutes ~/ 60, totalMinutes % 60);
}
```

### 드래그 중 스냅 미리보기 (선택 구현)

```dart
// DragTarget.onMove 콜백에서 임시 위치 표시
// ViewModel에 dragPreviewTime 상태 추가
// 타임라인에 반투명 미리보기 블록 렌더링
```

---

## 3-F. 블록 리사이즈

> 이미 배치된 TaskBlock의 하단 핸들을 드래그해 종료 시간을 조정한다.

### TaskBlock 수정

```dart
// task_block.dart — 하단 리사이즈 핸들 추가
Stack(
  children: [
    // 블록 본문
    _BlockContent(task: task),
    // 리사이즈 핸들 (하단 8px)
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // 드래그 delta → 새로운 endDateTime 계산
          _onResizeDrag(details.delta.dy);
        },
        onVerticalDragEnd: (_) {
          // ViewModel에 최종 시간 반영
          _onResizeEnd();
        },
        child: const _ResizeHandle(),  // 8px 높이, 중앙 아이콘
      ),
    ),
  ],
)
```

### 리사이즈 로직

```dart
// StatefulWidget으로 변환 필요
// 로컬 상태: _localEndTime (드래그 중 임시 종료 시간)

void _onResizeDrag(double deltaY) {
  final deltaMinutes = (deltaY / TimelineConstants.hourHeight * 60).round();
  final rawEnd = _localEndTime.add(Duration(minutes: deltaMinutes));
  // 최소 30분 보장
  final minEnd = task.startDateTime!.add(const Duration(minutes: 30));
  setState(() => _localEndTime = rawEnd.isAfter(minEnd) ? rawEnd : minEnd);
}

void _onResizeEnd() {
  final snappedEnd = _snap30min(_localEndTime);
  ref.read(dayViewViewModelProvider.notifier)
     .resizeTask(task.id, snappedEnd);
}
```

---

## 3-G. 완료 토글 & 완료 섹션

> TaskDock과 TaskBlock 모두에서 완료 처리가 가능해야 한다.

### 완료 토글

```dart
// TaskDockItem: 체크박스 onChanged
ref.read(taskDockViewModelProvider.notifier).toggleComplete(task.id);

// TaskBlock: 체크 아이콘 onTap
ref.read(dayViewViewModelProvider.notifier).toggleComplete(task.id);
// → ToggleCompleteUseCase 호출
```

### TaskDock 완료 섹션

```dart
// task_dock.dart
// 미배정 목록 아래에 완료 섹션 토글
GestureDetector(
  onTap: () => ref.read(taskDockViewModelProvider.notifier).toggleCompletedSection(),
  child: Row(
    children: [
      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
      Text('완료 (${completedTasks.length})'),
    ],
  ),
),
if (isExpanded)
  ...completedTasks.map((t) => TaskDockItem(task: t)),
```

### 완료된 TaskBlock 처리

```dart
// task_block.dart
// 완료 상태에서:
// - 배경 투명도: 0.4
// - 제목에 TextDecoration.lineThrough
// - 좌측 카테고리 바 회색 처리
```

---

## 3-H. AllDayEventBar

> TaskBlock과 다른 UI. 시간 없이 날짜 단위로 표시되는 이벤트.

### 생성 파일

```
lib/features/calendar/presentation/
├── states/all_day_event_state.dart
├── viewmodels/all_day_event_viewmodel.dart
└── widgets/all_day_event_bar.dart
```

### AllDayEventState

```dart
@freezed
sealed class AllDayEventState with _$AllDayEventState {
  const factory AllDayEventState.loading() = AllDayLoading;
  const factory AllDayEventState.data({required List<Task> events}) = AllDayData;
  const factory AllDayEventState.error(Failure failure) = AllDayError;
}
```

### AllDayEventViewModel

```dart
// isAllDay == true인 Task를 현재 날짜 기준으로 조회
// GetTasksUseCase 사용, isAllDay 필터링
@riverpod
class AllDayEventViewModel extends _$AllDayEventViewModel {
  @override
  Future<AllDayEventState> build() async { ... }
}
```

### AllDayEventBar 위젯

```dart
// DayViewPage의 Timeline 위에 배치 (AppBar 아래, Timeline 위)
// 이벤트가 없으면 최소 높이 (32px)
// 이벤트가 있으면 Chip 형태로 표시
Container(
  constraints: BoxConstraints(minHeight: 32),
  child: Wrap(
    children: events.map((e) => _AllDayChip(event: e)).toList(),
  ),
)
```

### DayViewPage 레이아웃 수정

```dart
Column(
  children: [
    AllDayEventBar(),      ← 추가
    const Divider(height: 1),
    Expanded(
      child: Row(
        children: [
          TaskDock(...),
          const VerticalDivider(width: 1),
          Expanded(child: TimelineArea(...)),
        ],
      ),
    ),
    QuickAddInput(),       ← 3-I에서 추가
  ],
)
```

---

## 3-I. QuickAddInput

> 하단 고정 입력창. 제목만 입력해서 미배정 태스크로 즉시 생성한다.

### 생성 파일

```
lib/features/calendar/presentation/widgets/
└── quick_add_input.dart
```

### QuickAddInput 위젯

```dart
// quick_add_input.dart
class QuickAddInput extends ConsumerStatefulWidget { ... }

// 내부 구성
Row(
  children: [
    // 텍스트 입력
    Expanded(
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: '태스크 추가...',
          border: InputBorder.none,
        ),
        onSubmitted: (title) => _createTask(title),  // 엔터 시
      ),
    ),
    // 더보기 버튼 → AddTaskSheet (Phase 5)
    IconButton(
      icon: const Icon(Icons.add_circle_outline),
      onPressed: () { /* AddTaskSheet 열기 */ },
    ),
  ],
)

void _createTask(String title) {
  if (title.trim().isEmpty) return;
  ref.read(taskDockViewModelProvider.notifier).createTask(title.trim());
  _controller.clear();
}
```

---

## 파일 생성 목록 (Phase 3 전체)

```
lib/features/calendar/presentation/
├── models/
│   └── task_drag_data.dart                          ← 3-E
├── states/
│   ├── day_view_state.dart                          ← 3-A
│   ├── task_dock_state.dart                         ← 3-A
│   └── all_day_event_state.dart                     ← 3-H
├── viewmodels/
│   ├── day_view_viewmodel.dart                      ← 3-A
│   ├── task_dock_viewmodel.dart                     ← 3-A
│   └── all_day_event_viewmodel.dart                 ← 3-H
└── widgets/
    ├── timeline/
    │   ├── timeline_constants.dart                  ← 3-B
    │   ├── timeline_area.dart                       ← 3-B, 3-C, 3-E 수정
    │   ├── timeline_grid_painter.dart               ← 3-B
    │   ├── task_block.dart                          ← 3-C, 3-F, 3-G 수정
    │   └── overlap_calculator.dart                  ← 3-C
    ├── task_dock/
    │   ├── task_dock.dart                           ← 3-D, 3-G 수정
    │   └── task_dock_item.dart                      ← 3-D, 3-E, 3-G 수정
    ├── all_day_event_bar.dart                       ← 3-H
    └── quick_add_input.dart                         ← 3-I

lib/features/calendar/presentation/pages/
└── day_view_page.dart                               ← 3-A, 3-H 수정 (플레이스홀더 제거)
```

---

## 기술 결정 사항

### 드래그 성능

| 방식 | 결정 |
|------|------|
| 드래그 고스트 | Flutter 기본 `Draggable.feedback` 사용 (Overlay 직접 관리 불필요) |
| 스냅 미리보기 | `DragTarget.onMove`에서 ViewModel에 임시 상태 업데이트 |
| 상태 업데이트 타이밍 | `onAcceptWithDetails`에서만 UseCase 호출 (매 프레임 호출 X) |

### 리사이즈 상태 관리

| 방식 | 결정 |
|------|------|
| 드래그 중 임시 높이 | `TaskBlock`을 `StatefulWidget`으로 선언, `_localEndTime` 로컬 상태 |
| 최종 반영 | `onVerticalDragEnd`에서 ViewModel을 통해 UseCase 호출 |

### TimelineArea 스크롤

| 방식 | 결정 |
|------|------|
| 스크롤 컨트롤러 | `TimelineArea` 내부 `ScrollController` (외부로 노출 X) |
| 초기 위치 | 현재 시간 기준 1시간 전으로 자동 스크롤 (initState) |
| DragTarget + ScrollView | `DragTarget`을 `SingleChildScrollView` 내부의 `Stack`에 배치 |

---

## 스텝별 개발 확인 체크리스트

### 3-A 완료 기준
- [ ] `flutter analyze` 에러 없음
- [ ] `flutter build bundle` 성공
- [ ] DayViewPage에서 ViewModel watch 후 로딩 상태 표시

### 3-B 완료 기준
- [ ] 00:00 ~ 23:30 그리드 선 렌더링
- [ ] 시간 라벨 표시
- [ ] 현재 시간 빨간 선 표시
- [ ] 세로 스크롤 정상 동작
- [ ] 현재 시간으로 초기 스크롤

### 3-C 완료 기준
- [ ] DB에 있는 스케줄된 태스크가 타임라인에 표시
- [ ] top/height가 시간에 맞게 계산됨
- [ ] 같은 시간대 태스크 나란히 배치

### 3-D 완료 기준
- [ ] 미배정 태스크 목록 표시
- [ ] 태스크 제목 + 카테고리 색상 표시

### 3-E 완료 기준
- [ ] Dock 아이템을 Timeline으로 드래그 가능
- [ ] 드롭 시 30분 스냅 적용
- [ ] ScheduleTaskUseCase 호출 → DB 저장 → 화면 반영

### 3-F 완료 기준
- [ ] 블록 하단 핸들 드래그 가능
- [ ] 최소 30분 보장
- [ ] UpdateTaskUseCase 호출 → DB 저장 → 화면 반영

### 3-G 완료 기준
- [ ] 체크박스 클릭 → 완료 상태 토글
- [ ] 완료된 태스크 Dock 완료 섹션으로 이동
- [ ] 완료 섹션 접기/펼치기
- [ ] 완료된 TaskBlock 시각적 처리

### 3-H 완료 기준
- [ ] AllDayEventBar 표시 (이벤트 없을 때 최소 높이)
- [ ] isAllDay 태스크 Chip 형태로 표시

### 3-I 완료 기준
- [ ] 하단 입력창에서 텍스트 입력 후 엔터
- [ ] CreateTaskUseCase 호출 → 미배정 Dock에 즉시 표시
- [ ] 입력창 초기화

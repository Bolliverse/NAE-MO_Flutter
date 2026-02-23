# NAE-MO 개발 계획 (PLAN)

> 기준 문서: [DEV_SPEC.md](DEV_SPEC.md), [ARCHITECTURE.md](ARCHITECTURE.md)
> 최종 업데이트: 2026-02-23

---

## 개발 단계 요약

| 단계 | 이름 | 핵심 결과물 | 비고 |
|------|------|-----------|------|
| Phase 0 | 프로젝트 세팅 | 아키텍처, 패키지, 라우팅 | ✅ 완료 |
| Phase 1 | 도메인 & 데이터 레이어 | Task/Category 모델, 로컬 DB, UseCase | 개발 시작점 |
| Phase 2 | 내비게이션 & 뷰 뼈대 | Day/Week/Month 라우팅, 빈 화면 | |
| Phase 3 | Day View (MVP 핵심) | Timeline, Task Dock, 드래그, 블록 리사이즈 | 가장 복잡한 단계 |
| Phase 4 | Month View | 달력 그리드, 카테고리 바, 필터 | |
| Phase 5 | Task CRUD UI | 추가/수정 모달, 카테고리 관리 | |
| Phase 6 | Week View | 7일 압축 타임라인, All-day 이벤트 | |
| Phase 7 | Phase 2 기능 | 반복 일정, 애니메이션, 보관함 | |

---

## Phase 0 — 프로젝트 세팅 ✅

**완료된 항목**
- Flutter 프로젝트 생성 (Android + iOS + Web)
- Clean Architecture 폴더 구조
- MVVM + Riverpod Notifier 패턴 확립
- GoRouter 라우팅 기반 설정
- Dio + Retrofit 네트워크 기반
- Pretendard Variable Font
- 설계 문서 (ARCHITECTURE.md)

---

## Phase 1 — 도메인 & 데이터 레이어

> MVP는 로컬 저장소만 사용한다. 백엔드 없이 `drift` (SQLite)로 데이터를 관리한다.

### 1-1. 패키지 추가

```yaml
dependencies:
  drift: ^2.x          # SQLite ORM
  sqlite3_flutter_libs: ^0.5.x
  path_provider: ^2.x  # DB 파일 경로

dev_dependencies:
  drift_dev: ^2.x
```

### 1-2. Domain Entity 정의

**`lib/features/task/domain/entities/task.dart`**

```
Task
├── id: String
├── title: String
├── categoryId: String?
├── isCompleted: bool
├── hasTime: bool
├── startDateTime: DateTime?
├── endDateTime: DateTime?
├── isAllDay: bool
├── isRecurring: bool
└── recurrenceRule: String?    (Phase 2)
```

**`lib/features/category/domain/entities/category.dart`**

```
Category
├── id: String
├── name: String
└── color: Color (int 저장)
```

### 1-3. Repository 인터페이스 (Domain)

```
TaskRepository
├── getTasks(DateTime date) → Result<List<Task>>
├── getTasksByRange(DateTime start, DateTime end) → Result<List<Task>>
├── getUnscheduledTasks() → Result<List<Task>>
├── createTask(CreateTaskParams) → Result<Task>
├── updateTask(UpdateTaskParams) → Result<Task>
├── deleteTask(String id) → Result<void>
└── toggleComplete(String id) → Result<Task>

CategoryRepository
├── getCategories() → Result<List<Category>>
├── createCategory(CreateCategoryParams) → Result<Category>
└── deleteCategory(String id) → Result<void>
```

### 1-4. UseCase 목록

| UseCase | 파일 |
|---------|------|
| `GetTasksUseCase` | 날짜별 일정 조회 |
| `GetTasksByRangeUseCase` | 날짜 범위 조회 (Week/Month) |
| `GetUnscheduledTasksUseCase` | Task Dock용 미배정 태스크 |
| `CreateTaskUseCase` | 태스크 생성 |
| `UpdateTaskUseCase` | 태스크 수정 (시간 포함) |
| `DeleteTaskUseCase` | 태스크 삭제 |
| `ToggleCompleteUseCase` | 완료 토글 |
| `ScheduleTaskUseCase` | Dock → Timeline 드래그 배정 |
| `GetCategoriesUseCase` | 카테고리 목록 |
| `CreateCategoryUseCase` | 카테고리 생성 |

### 1-5. Data Layer

```
features/task/data/
├── datasources/
│   ├── task_local_data_source.dart        # 인터페이스
│   └── task_local_data_source_impl.dart   # drift 구현체
├── mappers/
│   └── task_mapper.dart                   # TaskTableData ↔ Task
├── models/
│   └── task_table.dart                    # drift 테이블 정의
└── repositories/
    └── task_repository_impl.dart
```

### 1-6. 기본 카테고리 시드 데이터

앱 최초 실행 시 아래 카테고리를 자동 생성한다.

| 이름 | 색상 |
|------|------|
| 업무 | 파랑 |
| 개인 | 초록 |
| 건강 | 주황 |
| 학습 | 보라 |

---

## Phase 2 — 내비게이션 & 뷰 뼈대

### 2-1. 라우팅 구조

```
/ (초기 진입)
└── /calendar          → CalendarShellPage (공통 레이아웃)
    ├── /calendar/day  → DayViewPage
    ├── /calendar/week → WeekViewPage
    └── /calendar/month → MonthViewPage
```

GoRouter `ShellRoute`로 공통 상단 헤더(날짜 표시 + 뷰 전환 컨트롤)를 감싼다.

### 2-2. 뷰 전환 방식

| 전환 | 동작 |
|------|------|
| 헤더 탭 | Day / Week / Month 직접 탭 |
| Month 날짜 탭 | Day View로 이동 + 날짜 설정 |
| Week 이벤트 탭 | Day View로 이동 + 해당 시간 스크롤 |

### 2-3. 공통 상태

```dart
// core/providers/selected_date_provider.dart
// 현재 선택된 날짜 — 모든 뷰가 공유
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => DateTime.now();

  void select(DateTime date) => state = date;
}
```

---

## Phase 3 — Day View (MVP 핵심)

> 가장 기술적으로 복잡한 단계. 레이어 분리에 주의한다.

### 3-1. 레이아웃 구조

```
DayViewPage
├── DayViewHeader          (날짜 + 뷰 전환)
├── AllDayEventBar         (종일 이벤트 영역)
└── Row
    ├── TaskDock           (좌측 — 미배정 태스크 목록)
    └── TimelineArea       (우측 — 시간 그리드 + 이벤트 블록)
        └── DragOverlayLayer (드래그 시 최상위 레이어)
```

### 3-2. Timeline 기술 구현

```
TimelineArea
├── ScrollController (세로 스크롤)
├── CustomPaint — 30분 그리드 선 그리기
├── Stack — 이벤트 블록 절대 위치 배치
│   └── TaskBlock (각 이벤트, top/height를 시간으로 계산)
└── DragTarget — 드래그 수신
```

**시간 → 픽셀 변환 공식**
```dart
const double hourHeight = 60.0;   // 1시간 = 60px (30분 = 30px)

double timeToOffset(DateTime time) =>
    (time.hour + time.minute / 60) * hourHeight;

DateTime offsetToTime(double offset) {
  final totalMinutes = (offset / hourHeight * 60).round();
  // 30분 단위 스냅
  final snapped = (totalMinutes / 30).round() * 30;
  return DateTime(date.year, date.month, date.day,
      snapped ~/ 60, snapped % 60);
}
```

### 3-3. 드래그 시스템

드래그는 **3개의 레이어**로 분리한다.

```
Layer 1: TaskDock       — Draggable 위젯 (드래그 시작)
Layer 2: TimelineArea   — DragTarget (드래그 수신)
Layer 3: DragOverlay    — 드래그 중인 고스트 위젯 (Overlay 사용)
```

```dart
// 드래그 데이터 타입
class TaskDragData {
  final Task task;
  final Offset originalOffset;  // 드래그 시작 위치
}

// Dock → Timeline 드래그 흐름
// 1. TaskDock: Draggable<TaskDragData>
// 2. TimelineArea: DragTarget<TaskDragData>
//    onAcceptWithDetails → ScheduleTaskUseCase 호출
// 3. 블록 리사이즈: GestureDetector on 블록 하단 핸들
//    onVerticalDragUpdate → UpdateTaskUseCase 호출
```

### 3-4. ViewModel 목록

| ViewModel | 관리 상태 |
|-----------|---------|
| `DayViewViewModel` | 해당 날짜의 태스크 목록, 드래그 상태 |
| `TaskDockViewModel` | 미배정 태스크 목록, 완료 섹션 토글 |
| `AllDayEventViewModel` | 종일 이벤트 목록 |

### 3-5. 구현 순서 (Day View 내부)

1. TimelineArea — 그리드 렌더링 (이벤트 없이)
2. TimelineArea — TaskBlock 정적 배치
3. TaskDock — 미배정 태스크 목록
4. 드래그 Dock → Timeline 기본 동작
5. 블록 리사이즈
6. 완료 토글 + Completed 섹션 접기
7. AllDayEventBar
8. QuickAddInput (하단 빠른 입력)

---

## Phase 4 — Month View

### 4-1. 레이아웃

```
MonthViewPage
├── CategoryFilterBar      (카테고리 토글 필터)
├── MonthGrid              (TableCalendar 또는 Custom)
│   └── DateCell × N      (날짜 셀)
│       ├── CategoryBar × max  (카테고리 막대)
│       └── OverflowBadge  ("+N" 표시)
└── (날짜 탭 → Day View 이동)
```

### 4-2. 기술 선택: 커스텀 그리드

`table_calendar` 패키지 대신 **직접 구현**한다.
이유: 카테고리 바 커스텀 렌더링, 드래그 확장성 필요.

```dart
// 날짜 셀 카테고리 바
// 카테고리별 태스크 수 집계 → 색상 막대 표시
// 셀 높이 고정 → max 3개 표시, 초과 시 "+N"
```

### 4-3. 성능 고려

- `GridView.builder` 사용 (42셀 — 6주 × 7일)
- 월 데이터는 `GetTasksByRangeUseCase`로 한 번에 조회
- 카테고리 집계는 ViewModel에서 `Map<String, List<Task>>` 형태로 미리 계산

---

## Phase 5 — Task CRUD UI

### 5-1. 태스크 추가 모달 (Bottom Sheet)

```
AddTaskSheet
├── 제목 입력 (TextField)
├── 카테고리 선택 (Chip 목록)
├── 날짜 선택 (DatePicker, optional)
├── 시간 선택 (TimePicker, optional)
├── 종일 이벤트 토글
└── 저장 버튼
```

### 5-2. 태스크 수정 모달

```
EditTaskSheet
├── (AddTaskSheet의 모든 필드)
├── 시간/날짜 수정
├── 길이(duration) 수정
└── 삭제 버튼 (확인 다이얼로그)
```

### 5-3. QuickAddInput

하단 고정 입력창. 제목만 입력 → 미배정 태스크로 즉시 생성.

```dart
// 엔터 → CreateTaskUseCase(title: text, hasTime: false)
// 더보기(+) 버튼 → AddTaskSheet 열기
```

---

## Phase 6 — Week View

### 6-1. 레이아웃

```
WeekViewPage
├── WeekHeader       (7일 날짜 헤더)
├── AllDayEventBar   (Week용 — 멀티데이 이벤트)
└── HorizontalScrollView
    └── Row (7열)
        └── TimelineArea × 7  (각 날짜 압축 타임라인)
```

### 6-2. 기술 고려사항

- 가로 + 세로 동시 스크롤 → `InteractiveViewer` 또는 `LinkedScrollController`
- 이벤트 블록은 Day View 블록보다 좁게 렌더링 (최소 정보만 표시)
- 멀티데이 All-day 이벤트: 날짜 span만큼 가로로 늘어나는 위젯

---

## Phase 7 — Phase 2 기능

> MVP 이후 구현. 현재 아키텍처로 확장 가능하도록 설계해둔다.

- **반복 일정**: `recurrenceRule` 필드 (iCal RRULE 형식) + `RecurrenceExpander` 유틸
- **완료 보관함**: `getCompletedTasks()` + 별도 Archive 페이지
- **애니메이션**: 뷰 전환 Hero, 블록 배치 애니메이션
- **위젯 개선**: 태스크 블록 오버랩 처리 (같은 시간대 이벤트 나란히 배치)

---

## 기술 구현 결정사항

### 로컬 DB: drift (SQLite)

```
shared_preferences → 설정값, 필터 상태 등 단순 키-값
drift (SQLite)     → Task, Category 구조화 데이터
```

### 드래그 성능

```
❌ setState를 드래그 매 프레임마다 호출 → 성능 저하
✅ Overlay + AnimatedBuilder로 드래그 고스트를 별도 레이어에서 처리
✅ DragTarget.onWillAccept에서 스냅 미리보기만 업데이트
```

### 타임라인 렌더링

```
❌ ListView.builder — 그리드와 이벤트 블록 절대 위치 조합이 어려움
✅ SingleChildScrollView + Stack — 고정 높이(24h × 60px = 1440px)에 블록을 절대 위치로 배치
```

### 이벤트 블록 오버랩 처리

```
같은 시간대 이벤트가 겹칠 경우:
- 겹치는 이벤트 그룹을 계산 (OverlapCalculator 유틸)
- 그룹 내 이벤트 수에 따라 블록 너비를 1/N으로 분할
- 각 블록에 left offset 부여
```

---

## 파일 생성 계획 (Phase 1 ~ 3 기준)

```
lib/
├── features/
│   ├── task/
│   │   ├── domain/
│   │   │   ├── entities/task.dart
│   │   │   ├── repositories/task_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_tasks_use_case.dart
│   │   │       ├── get_tasks_by_range_use_case.dart
│   │   │       ├── get_unscheduled_tasks_use_case.dart
│   │   │       ├── create_task_use_case.dart
│   │   │       ├── update_task_use_case.dart
│   │   │       ├── delete_task_use_case.dart
│   │   │       ├── toggle_complete_use_case.dart
│   │   │       ├── schedule_task_use_case.dart
│   │   │       └── params/
│   │   │           ├── create_task_params.dart
│   │   │           └── update_task_params.dart
│   │   └── data/
│   │       ├── datasources/
│   │       │   ├── task_local_data_source.dart
│   │       │   └── task_local_data_source_impl.dart
│   │       ├── mappers/task_mapper.dart
│   │       ├── models/task_table.dart
│   │       └── repositories/task_repository_impl.dart
│   │
│   ├── category/
│   │   ├── domain/
│   │   │   ├── entities/category.dart
│   │   │   ├── repositories/category_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_categories_use_case.dart
│   │   │       └── create_category_use_case.dart
│   │   └── data/
│   │       ├── datasources/category_local_data_source.dart
│   │       ├── mappers/category_mapper.dart
│   │       ├── models/category_table.dart
│   │       └── repositories/category_repository_impl.dart
│   │
│   └── calendar/
│       └── presentation/
│           ├── pages/
│           │   ├── calendar_shell_page.dart   # ShellRoute 공통 레이아웃
│           │   ├── day_view_page.dart
│           │   ├── week_view_page.dart
│           │   └── month_view_page.dart
│           ├── viewmodels/
│           │   ├── day_view_viewmodel.dart
│           │   ├── task_dock_viewmodel.dart
│           │   ├── all_day_event_viewmodel.dart
│           │   └── month_view_viewmodel.dart
│           ├── states/
│           │   ├── day_view_state.dart
│           │   ├── task_dock_state.dart
│           │   └── month_view_state.dart
│           └── widgets/
│               ├── timeline/
│               │   ├── timeline_area.dart
│               │   ├── timeline_grid_painter.dart   # CustomPainter
│               │   └── task_block.dart
│               ├── task_dock/
│               │   ├── task_dock.dart
│               │   └── task_dock_item.dart
│               ├── all_day_event_bar.dart
│               ├── quick_add_input.dart
│               └── month/
│                   ├── month_grid.dart
│                   └── date_cell.dart
│
└── core/
    ├── database/
    │   └── app_database.dart    # drift AppDatabase 설정
    └── providers/
        └── selected_date_provider.dart
```

---

## 개발 시작 순서 (즉시 시작 가능한 것부터)

```
1. drift 패키지 추가 및 AppDatabase 설정
2. Category entity + 로컬 CRUD
3. Task entity + 로컬 CRUD
4. SelectedDate Provider
5. GoRouter ShellRoute 설정 (Day/Week/Month 라우팅)
6. TimelineArea — 그리드 렌더링 (빈 타임라인)
7. TaskDock — 정적 목록 렌더링
8. TaskBlock — 타임라인 위 블록 표시
9. 드래그 시스템 구현
10. 완료 토글, CRUD 모달
```

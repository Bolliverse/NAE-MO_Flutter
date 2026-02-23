# 📱 Scheduling App Development Specification (MVP)

## 1. App Structure Overview

### Core Views

1.  Day View (Default)
2.  Week View
3.  Month View

### Shared Components

-   Task Dock
-   Timeline Grid
-   All-Day Event Bar
-   Category Filter Bar
-   Completed Section
-   Floating Add Input

------------------------------------------------------------------------

# 2. Pages & Features

## 🗓 2.1 Day View

### Layout

-   Left: Task Dock
-   Right: Timeline (30-minute grid)
-   Top: Date header + View switch control
-   Bottom: Quick Add input

### Features

-   Drag task from Dock → Timeline
-   Default 30-min block creation
-   Resize block via drag
-   Tap block → Edit modal
-   Check/uncheck task
-   Completed tasks collapse section
-   All-day event bar at top
-   Category color display
-   Scrollable timeline

------------------------------------------------------------------------

## 📅 2.2 Week View

### Layout

-   Left: Task Dock
-   Right: 7-day compressed timeline
-   Top: Week header
-   All-day events section per week

### Features

-   Drag Dock task to any day/time
-   Compressed block view (minimal text)
-   Tap → Expand to Day View
-   Multi-day all-day events
-   Resize multi-day events
-   Scroll vertical time grid

------------------------------------------------------------------------

## 🗓 2.3 Month View

### Layout

-   Full calendar grid
-   Top: Category & completion filter bar

### Features

-   Each date shows stacked category bars
-   Max visible bars per date
-   "+N" overflow indicator
-   Tap date → Open Day View
-   Toggle category filters
-   Toggle completed visibility

------------------------------------------------------------------------

# 3. Shared Feature Modules

## 3.1 Task Dock Module

### Responsibilities

-   Display unscheduled tasks
-   Display scheduled tasks (with indicator)
-   Display recurring task suggestions
-   Allow drag initiation
-   Allow task completion
-   Collapsible Completed section

------------------------------------------------------------------------

## 3.2 Timeline Module

### Responsibilities

-   30-minute grid rendering
-   Event block positioning
-   Drag target handling
-   Block resizing
-   Collision detection
-   Scroll handling

------------------------------------------------------------------------

## 3.3 All-Day Event Module

### Responsibilities

-   Display date-based events
-   Handle multi-day rendering
-   Drag to adjust date span
-   Show consistently in Day & Week

------------------------------------------------------------------------

## 3.4 Task Creation & Editing

### Add Task Modal

-   Title
-   Category
-   Optional time
-   Optional date
-   Repeat toggle

### Edit Task Modal

-   Modify time/date
-   Modify duration
-   Change category
-   Delete task

------------------------------------------------------------------------

# 4. Data Model Requirements

## Task Object

-   id
-   title
-   category
-   isCompleted
-   hasTime
-   startDateTime (nullable)
-   endDateTime (nullable)
-   isRecurring
-   recurrenceRule (optional)

------------------------------------------------------------------------

# 5. Navigation Flow

-   Default launch → Day View
-   Pinch or header toggle → Week View
-   Further expand → Month View
-   Tap date in Month → Day View
-   Tap event in Week → Day View

------------------------------------------------------------------------

# 6. MVP Scope (Phase 1)

### Must Have

-   Day View
-   Task Dock
-   Drag to schedule
-   Block resize
-   Completion toggle
-   Basic Month View
-   Category color system

### Phase 2

-   Recurring tasks
-   Week multi-day events
-   Completed archive page
-   UI animations polish

------------------------------------------------------------------------

# 7. Technical Considerations (Flutter)

-   Use CustomScrollView + Slivers
-   Separate drag layer from scroll layer
-   Use state management (Riverpod / Bloc recommended)
-   Optimize for smooth drag performance
-   Handle overlapping event stacking logic

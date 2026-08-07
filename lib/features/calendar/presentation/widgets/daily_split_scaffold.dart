import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

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

class DailySplitScaffold extends StatefulWidget {
  const DailySplitScaffold({
    super.key,
    required this.header,
    required this.calendarPinnedBuilder,
    required this.todoPinnedBuilder,
    required this.calendarTimelineBuilder,
    required this.todoTimelineBuilder,
    this.initialPane = DailyPane.calendar,
    this.onPaneChanged,
    this.pinnedHeight = 112,
    this.initialTimelineOffset = 0,
  });

  final Widget header;
  final DailyPaneBuilder calendarPinnedBuilder;
  final DailyPaneBuilder todoPinnedBuilder;
  final DailyPaneBuilder calendarTimelineBuilder;
  final DailyPaneBuilder todoTimelineBuilder;
  final DailyPane initialPane;
  final ValueChanged<DailyPane>? onPaneChanged;
  final double pinnedHeight;
  final double initialTimelineOffset;

  @override
  State<DailySplitScaffold> createState() => _DailySplitScaffoldState();
}

class _DailySplitScaffoldState extends State<DailySplitScaffold>
    with SingleTickerProviderStateMixin {
  static const _calendarExpandedFraction = .82;
  static const _calendarCompactFraction = .18;
  static const _snapVelocity = 300.0;
  static const _paneGap = 8.0;

  late final AnimationController _snapController;
  late final ScrollController _timelineController;
  Animation<double>? _snapAnimation;
  late DailyPane _activePane;
  late double _progress;
  double _availableWidth = 1;

  @override
  void initState() {
    super.initState();
    _activePane = widget.initialPane;
    _progress = _progressFor(widget.initialPane);
    _timelineController = ScrollController(
      initialScrollOffset: widget.initialTimelineOffset,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )
      ..addListener(_handleAnimationTick)
      ..addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant DailySplitScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPane != widget.initialPane) {
      _showPane(widget.initialPane, notify: false);
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  double get _calendarFraction => lerpDouble(
        _calendarExpandedFraction,
        _calendarCompactFraction,
        _progress,
      )!;

  void _handleAnimationTick() {
    final animation = _snapAnimation;
    if (animation == null) return;
    setState(() => _progress = animation.value);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final settledPane = _progress < .5 ? DailyPane.calendar : DailyPane.todo;
    if (settledPane == _activePane) return;
    _activePane = settledPane;
    widget.onPaneChanged?.call(settledPane);
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _snapController.stop();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta == null) return;
    setState(() {
      _progress = (_progress - delta / _availableWidth).clamp(0.0, 1.0);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final target = velocity.abs() >= _snapVelocity
        ? (velocity < 0 ? DailyPane.todo : DailyPane.calendar)
        : (_progress < .5 ? DailyPane.calendar : DailyPane.todo);
    _showPane(target);
  }

  void _showPane(DailyPane pane, {bool notify = true}) {
    final target = _progressFor(pane);
    if ((_progress - target).abs() < .001) {
      if (pane != _activePane) {
        _activePane = pane;
        if (notify) widget.onPaneChanged?.call(pane);
      }
      return;
    }

    _snapAnimation = Tween<double>(
      begin: _progress,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _snapController,
        curve: Curves.easeOutCubic,
      ),
    );
    _snapController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          widget.header,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _availableWidth = constraints.maxWidth;
                return GestureDetector(
                  key: const Key('dailySplitGestureArea'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _handleHorizontalDragStart,
                  onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                  onHorizontalDragEnd: _handleHorizontalDragEnd,
                  child: Column(
                    children: [
                      SizedBox(
                        height: widget.pinnedHeight,
                        child: _buildPaneRow(
                          calendarBuilder: widget.calendarPinnedBuilder,
                          todoBuilder: widget.todoPinnedBuilder,
                          calendarPaneKey: const Key('dailyCalendarPinnedPane'),
                          todoPaneKey: const Key('dailyTodoPinnedPane'),
                          calendarCompactKey:
                              const Key('dailyCalendarCompactTapTarget'),
                          todoCompactKey:
                              const Key('dailyTodoCompactTapTarget'),
                          exposeCompactSemantics: true,
                          paneHeight: widget.pinnedHeight,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const Key('dailyTimelineScroll'),
                          controller: _timelineController,
                          child: _buildPaneRow(
                            calendarBuilder: widget.calendarTimelineBuilder,
                            todoBuilder: widget.todoTimelineBuilder,
                            calendarPaneKey:
                                const Key('dailyCalendarTimelinePane'),
                            todoPaneKey: const Key('dailyTodoTimelinePane'),
                            calendarCompactKey: const Key(
                              'dailyCalendarTimelineCompactTapTarget',
                            ),
                            todoCompactKey: const Key(
                              'dailyTodoTimelineCompactTapTarget',
                            ),
                            exposeCompactSemantics: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaneRow({
    required DailyPaneBuilder calendarBuilder,
    required DailyPaneBuilder todoBuilder,
    required Key calendarPaneKey,
    required Key todoPaneKey,
    required Key calendarCompactKey,
    required Key todoCompactKey,
    required bool exposeCompactSemantics,
    double? paneHeight,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth - _paneGap).clamp(
          0.0,
          double.infinity,
        );
        final calendarWidth = contentWidth * _calendarFraction;
        final todoWidth = contentWidth - calendarWidth;
        final calendarLayout = DailyPaneLayout(
          fraction: _calendarFraction,
        );
        final todoLayout = DailyPaneLayout(
          fraction: 1 - _calendarFraction,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: calendarPaneKey,
              width: calendarWidth,
              height: paneHeight,
              child: _paneTarget(
                context: context,
                pane: DailyPane.calendar,
                layout: calendarLayout,
                builder: calendarBuilder,
                compactKey: calendarCompactKey,
                exposeSemantics: exposeCompactSemantics,
              ),
            ),
            const SizedBox(width: _paneGap),
            SizedBox(
              key: todoPaneKey,
              width: todoWidth,
              height: paneHeight,
              child: _paneTarget(
                context: context,
                pane: DailyPane.todo,
                layout: todoLayout,
                builder: todoBuilder,
                compactKey: todoCompactKey,
                exposeSemantics: exposeCompactSemantics,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _paneTarget({
    required BuildContext context,
    required DailyPane pane,
    required DailyPaneLayout layout,
    required DailyPaneBuilder builder,
    required Key compactKey,
    required bool exposeSemantics,
  }) {
    final child = ClipRect(child: builder(context, layout));
    if (!layout.isCompact) return child;

    final tapTarget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showPane(pane),
      child: child,
    );
    if (!exposeSemantics) {
      return ExcludeSemantics(
        child: KeyedSubtree(key: compactKey, child: tapTarget),
      );
    }

    final paneName = pane == DailyPane.calendar ? 'Calendar' : 'Todo';
    return Semantics(
      key: compactKey,
      container: true,
      button: true,
      label: '$paneName 화면 펼치기',
      excludeSemantics: true,
      onTap: () => _showPane(pane),
      child: tapTarget,
    );
  }

  static double _progressFor(DailyPane pane) {
    return pane == DailyPane.calendar ? 0 : 1;
  }
}

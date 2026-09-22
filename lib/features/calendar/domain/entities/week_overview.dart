import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';

DateTime weekStartFor(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day - local.weekday + 1);
}

DateTime calendarDayOffset(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

class WeekDaySummary {
  WeekDaySummary(
      {required this.date,
      required List<TodayEntry> events,
      required this.firstTodo,
      required this.todoCount,
      required this.completedTodoCount,
      required this.eventCount})
      : events = List.unmodifiable(events);
  final DateTime date;
  final List<TodayEntry> events;
  final TodayEntry? firstTodo;
  final int eventCount;
  final int todoCount;
  final int completedTodoCount;
}

class WeekOverview {
  WeekOverview({required this.start, required List<WeekDaySummary> days})
      : days = List.unmodifiable(days);
  final DateTime start;
  final List<WeekDaySummary> days;
  DateTime get end => calendarDayOffset(start, 6);
}

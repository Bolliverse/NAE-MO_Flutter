import 'package:nae_mo/features/category/domain/entities/category.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

class TodayEntry {
  final Task task;
  final Category? category;

  const TodayEntry({
    required this.task,
    this.category,
  });
}

class TodayOverview {
  final DateTime date;
  final List<TodayEntry> overdueTodos;
  final List<TodayEntry> allDayEvents;
  final List<TodayEntry> timelineItems;
  final List<TodayEntry> untimedTodos;
  final List<TodayEntry> completedTodos;

  const TodayOverview({
    required this.date,
    required this.overdueTodos,
    required this.allDayEvents,
    required this.timelineItems,
    required this.untimedTodos,
    required this.completedTodos,
  });
}

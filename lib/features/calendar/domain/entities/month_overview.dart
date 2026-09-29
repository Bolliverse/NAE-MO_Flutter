import 'package:nae_mo/features/calendar/domain/entities/today_overview.dart';
import 'package:nae_mo/features/category/domain/entities/category.dart';

DateTime localCalendarDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime monthStartFor(DateTime date) {
  final day = localCalendarDay(date);
  return DateTime(day.year, day.month);
}

enum MonthMarkerShape { event, todo, mixed }

class MonthCategoryMarker {
  const MonthCategoryMarker({
    required this.category,
    required this.shape,
    required this.isChecked,
  });

  final Category? category;
  final MonthMarkerShape shape;
  final bool isChecked;
}

class MonthDaySummary {
  MonthDaySummary({
    required this.date,
    required List<MonthCategoryMarker> markers,
    required List<TodayEntry> entries,
  })  : markers = List.unmodifiable(markers),
        entries = List.unmodifiable(entries);

  final DateTime date;
  final List<MonthCategoryMarker> markers;
  final List<TodayEntry> entries;
}

class MonthOverview {
  MonthOverview({required this.start, required List<MonthDaySummary> days})
      : days = List.unmodifiable(days);

  final DateTime start;
  final List<MonthDaySummary> days;
  MonthDaySummary day(int dayOfMonth) => days[dayOfMonth - 1];
}

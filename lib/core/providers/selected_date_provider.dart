import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_date_provider.g.dart';

/// Day/Week/Month View가 공유하는 현재 선택된 날짜
@Riverpod(keepAlive: true)
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() => _today();

  void select(DateTime date) => state = date;
  void goToToday() => state = _today();
  void addDays(int days) => state = state.add(Duration(days: days));

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

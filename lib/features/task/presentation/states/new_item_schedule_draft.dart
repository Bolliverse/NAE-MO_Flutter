import 'package:flutter/material.dart';

enum NewItemKind {
  event,
  todo,
}

enum NewItemTimeMode {
  timed,
  allDay,
  untimed,
}

@immutable
class NewItemScheduleDraft {
  const NewItemScheduleDraft({
    this.kind = NewItemKind.event,
    this.eventMode = NewItemTimeMode.timed,
    this.todoMode = NewItemTimeMode.untimed,
    this.startTime,
    this.endTime,
  });

  static const invalidTimeRangeMessage = '종료 시간은 시작 시간보다 늦어야 합니다.';

  final NewItemKind kind;
  final NewItemTimeMode eventMode;
  final NewItemTimeMode todoMode;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  NewItemTimeMode get activeMode => switch (kind) {
        NewItemKind.event => eventMode,
        NewItemKind.todo => todoMode,
      };

  bool get showsTimeFields => activeMode == NewItemTimeMode.timed;

  String? get timeRangeError {
    if (!showsTimeFields || startTime == null || endTime == null) return null;

    final startMinutes = _minutes(startTime!);
    final endMinutes = _minutes(endTime!);
    return endMinutes <= startMinutes ? invalidTimeRangeMessage : null;
  }

  NewItemScheduleDraft withKind(NewItemKind value) {
    return _copyWith(kind: value);
  }

  NewItemScheduleDraft withMode(NewItemTimeMode value) {
    assert(_supportsMode(kind, value), '$kind does not support $value');
    return switch (kind) {
      NewItemKind.event => _copyWith(eventMode: value),
      NewItemKind.todo => _copyWith(todoMode: value),
    };
  }

  NewItemScheduleDraft withStartTime(TimeOfDay value) {
    return _copyWith(startTime: value);
  }

  NewItemScheduleDraft withEndTime(TimeOfDay value) {
    return _copyWith(endTime: value);
  }

  NewItemScheduleDraft _copyWith({
    NewItemKind? kind,
    NewItemTimeMode? eventMode,
    NewItemTimeMode? todoMode,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return NewItemScheduleDraft(
      kind: kind ?? this.kind,
      eventMode: eventMode ?? this.eventMode,
      todoMode: todoMode ?? this.todoMode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  static bool _supportsMode(NewItemKind kind, NewItemTimeMode mode) {
    return switch (kind) {
      NewItemKind.event =>
        mode == NewItemTimeMode.timed || mode == NewItemTimeMode.allDay,
      NewItemKind.todo =>
        mode == NewItemTimeMode.timed || mode == NewItemTimeMode.untimed,
    };
  }

  static int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
}

import 'package:drift/drift.dart';
import 'package:nae_mo/features/task/domain/entities/task.dart';

class TaskTable extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get kind =>
      textEnum<TaskKind>().withDefault(const Constant('todo'))();
  DateTimeColumn get targetDate => dateTime().withDefault(currentDateAndTime)();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startDateTime => dateTime().nullable()();
  DateTimeColumn get endDateTime => dateTime().nullable()();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

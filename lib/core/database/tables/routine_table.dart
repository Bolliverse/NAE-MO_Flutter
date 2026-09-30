import 'package:drift/drift.dart';

/// Routine definitions are templates. Occurrences are calculated on demand.
class RoutineTable extends Table {
  @override
  String get tableName => 'routines';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get kind => text()(); // event or todo
  TextColumn get categoryId => text().nullable()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get frequency => text()();
  TextColumn get creationMode => text()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  TextColumn get customUnit => text().nullable()();
  TextColumn get weekdays => text().withDefault(const Constant(''))();

  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
  BoolColumn get isAllDay => boolean().withDefault(const Constant(false))();
  IntColumn get startMinute => integer().nullable()();
  IntColumn get endMinute => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

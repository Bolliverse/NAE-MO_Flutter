// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoryTableTable extends CategoryTable
    with TableInfo<$CategoryTableTable, CategoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, name, color, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoryTableTable createAlias(String alias) {
    return $CategoryTableTable(attachedDatabase, alias);
  }
}

class CategoryTableData extends DataClass
    implements Insertable<CategoryTableData> {
  final String id;
  final String name;
  final int color;
  final int sortOrder;
  const CategoryTableData(
      {required this.id,
      required this.name,
      required this.color,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoryTableCompanion toCompanion(bool nullToAbsent) {
    return CategoryTableCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryTableData copyWith(
          {String? id, String? name, int? color, int? sortOrder}) =>
      CategoryTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  CategoryTableData copyWithCompanion(CategoryTableCompanion data) {
    return CategoryTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder);
}

class CategoryTableCompanion extends UpdateCompanion<CategoryTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoryTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryTableCompanion.insert({
    required String id,
    required String name,
    required int color,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        color = Value(color);
  static Insertable<CategoryTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? color,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return CategoryTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTableTable extends TaskTable
    with TableInfo<$TaskTableTable, TaskTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('todo'))
          .withConverter<TaskKind>($TaskTableTable.$converterkind);
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
      'target_date', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasTimeMeta =
      const VerificationMeta('hasTime');
  @override
  late final GeneratedColumn<bool> hasTime = GeneratedColumn<bool>(
      'has_time', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("has_time" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _startDateTimeMeta =
      const VerificationMeta('startDateTime');
  @override
  late final GeneratedColumn<DateTime> startDateTime =
      GeneratedColumn<DateTime>('start_date_time', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endDateTimeMeta =
      const VerificationMeta('endDateTime');
  @override
  late final GeneratedColumn<DateTime> endDateTime = GeneratedColumn<DateTime>(
      'end_date_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isAllDayMeta =
      const VerificationMeta('isAllDay');
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
      'is_all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isRecurringMeta =
      const VerificationMeta('isRecurring');
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
      'is_recurring', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_recurring" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _recurrenceRuleMeta =
      const VerificationMeta('recurrenceRule');
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
      'recurrence_rule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        kind,
        targetDate,
        categoryId,
        routineId,
        isCompleted,
        hasTime,
        startDateTime,
        endDateTime,
        isAllDay,
        isRecurring,
        recurrenceRule,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<TaskTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    context.handle(_kindMeta, const VerificationResult.success());
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('has_time')) {
      context.handle(_hasTimeMeta,
          hasTime.isAcceptableOrUnknown(data['has_time']!, _hasTimeMeta));
    }
    if (data.containsKey('start_date_time')) {
      context.handle(
          _startDateTimeMeta,
          startDateTime.isAcceptableOrUnknown(
              data['start_date_time']!, _startDateTimeMeta));
    }
    if (data.containsKey('end_date_time')) {
      context.handle(
          _endDateTimeMeta,
          endDateTime.isAcceptableOrUnknown(
              data['end_date_time']!, _endDateTimeMeta));
    }
    if (data.containsKey('is_all_day')) {
      context.handle(_isAllDayMeta,
          isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta));
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
          _isRecurringMeta,
          isRecurring.isAcceptableOrUnknown(
              data['is_recurring']!, _isRecurringMeta));
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
          _recurrenceRuleMeta,
          recurrenceRule.isAcceptableOrUnknown(
              data['recurrence_rule']!, _recurrenceRuleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      kind: $TaskTableTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}target_date'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id']),
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      hasTime: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_time'])!,
      startDateTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}start_date_time']),
      endDateTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date_time']),
      isAllDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_all_day'])!,
      isRecurring: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_recurring'])!,
      recurrenceRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence_rule']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TaskTableTable createAlias(String alias) {
    return $TaskTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskKind, String, String> $converterkind =
      const EnumNameConverter<TaskKind>(TaskKind.values);
}

class TaskTableData extends DataClass implements Insertable<TaskTableData> {
  final String id;
  final String title;
  final TaskKind kind;
  final DateTime targetDate;
  final String? categoryId;

  /// Links a materialized occurrence back to its routine definition.
  final String? routineId;
  final bool isCompleted;
  final bool hasTime;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool isAllDay;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime createdAt;
  const TaskTableData(
      {required this.id,
      required this.title,
      required this.kind,
      required this.targetDate,
      this.categoryId,
      this.routineId,
      required this.isCompleted,
      required this.hasTime,
      this.startDateTime,
      this.endDateTime,
      required this.isAllDay,
      required this.isRecurring,
      this.recurrenceRule,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    {
      map['kind'] =
          Variable<String>($TaskTableTable.$converterkind.toSql(kind));
    }
    map['target_date'] = Variable<DateTime>(targetDate);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['has_time'] = Variable<bool>(hasTime);
    if (!nullToAbsent || startDateTime != null) {
      map['start_date_time'] = Variable<DateTime>(startDateTime);
    }
    if (!nullToAbsent || endDateTime != null) {
      map['end_date_time'] = Variable<DateTime>(endDateTime);
    }
    map['is_all_day'] = Variable<bool>(isAllDay);
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TaskTableCompanion toCompanion(bool nullToAbsent) {
    return TaskTableCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      targetDate: Value(targetDate),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      isCompleted: Value(isCompleted),
      hasTime: Value(hasTime),
      startDateTime: startDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startDateTime),
      endDateTime: endDateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endDateTime),
      isAllDay: Value(isAllDay),
      isRecurring: Value(isRecurring),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      createdAt: Value(createdAt),
    );
  }

  factory TaskTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: $TaskTableTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      hasTime: serializer.fromJson<bool>(json['hasTime']),
      startDateTime: serializer.fromJson<DateTime?>(json['startDateTime']),
      endDateTime: serializer.fromJson<DateTime?>(json['endDateTime']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer
          .toJson<String>($TaskTableTable.$converterkind.toJson(kind)),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'categoryId': serializer.toJson<String?>(categoryId),
      'routineId': serializer.toJson<String?>(routineId),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'hasTime': serializer.toJson<bool>(hasTime),
      'startDateTime': serializer.toJson<DateTime?>(startDateTime),
      'endDateTime': serializer.toJson<DateTime?>(endDateTime),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TaskTableData copyWith(
          {String? id,
          String? title,
          TaskKind? kind,
          DateTime? targetDate,
          Value<String?> categoryId = const Value.absent(),
          Value<String?> routineId = const Value.absent(),
          bool? isCompleted,
          bool? hasTime,
          Value<DateTime?> startDateTime = const Value.absent(),
          Value<DateTime?> endDateTime = const Value.absent(),
          bool? isAllDay,
          bool? isRecurring,
          Value<String?> recurrenceRule = const Value.absent(),
          DateTime? createdAt}) =>
      TaskTableData(
        id: id ?? this.id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        targetDate: targetDate ?? this.targetDate,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        routineId: routineId.present ? routineId.value : this.routineId,
        isCompleted: isCompleted ?? this.isCompleted,
        hasTime: hasTime ?? this.hasTime,
        startDateTime:
            startDateTime.present ? startDateTime.value : this.startDateTime,
        endDateTime: endDateTime.present ? endDateTime.value : this.endDateTime,
        isAllDay: isAllDay ?? this.isAllDay,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceRule:
            recurrenceRule.present ? recurrenceRule.value : this.recurrenceRule,
        createdAt: createdAt ?? this.createdAt,
      );
  TaskTableData copyWithCompanion(TaskTableCompanion data) {
    return TaskTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      hasTime: data.hasTime.present ? data.hasTime.value : this.hasTime,
      startDateTime: data.startDateTime.present
          ? data.startDateTime.value
          : this.startDateTime,
      endDateTime:
          data.endDateTime.present ? data.endDateTime.value : this.endDateTime,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      isRecurring:
          data.isRecurring.present ? data.isRecurring.value : this.isRecurring,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('targetDate: $targetDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('routineId: $routineId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('hasTime: $hasTime, ')
          ..write('startDateTime: $startDateTime, ')
          ..write('endDateTime: $endDateTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      kind,
      targetDate,
      categoryId,
      routineId,
      isCompleted,
      hasTime,
      startDateTime,
      endDateTime,
      isAllDay,
      isRecurring,
      recurrenceRule,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.targetDate == this.targetDate &&
          other.categoryId == this.categoryId &&
          other.routineId == this.routineId &&
          other.isCompleted == this.isCompleted &&
          other.hasTime == this.hasTime &&
          other.startDateTime == this.startDateTime &&
          other.endDateTime == this.endDateTime &&
          other.isAllDay == this.isAllDay &&
          other.isRecurring == this.isRecurring &&
          other.recurrenceRule == this.recurrenceRule &&
          other.createdAt == this.createdAt);
}

class TaskTableCompanion extends UpdateCompanion<TaskTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<TaskKind> kind;
  final Value<DateTime> targetDate;
  final Value<String?> categoryId;
  final Value<String?> routineId;
  final Value<bool> isCompleted;
  final Value<bool> hasTime;
  final Value<DateTime?> startDateTime;
  final Value<DateTime?> endDateTime;
  final Value<bool> isAllDay;
  final Value<bool> isRecurring;
  final Value<String?> recurrenceRule;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TaskTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.startDateTime = const Value.absent(),
    this.endDateTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTableCompanion.insert({
    required String id,
    required String title,
    this.kind = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.routineId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.startDateTime = const Value.absent(),
    this.endDateTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title);
  static Insertable<TaskTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<DateTime>? targetDate,
    Expression<String>? categoryId,
    Expression<String>? routineId,
    Expression<bool>? isCompleted,
    Expression<bool>? hasTime,
    Expression<DateTime>? startDateTime,
    Expression<DateTime>? endDateTime,
    Expression<bool>? isAllDay,
    Expression<bool>? isRecurring,
    Expression<String>? recurrenceRule,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (targetDate != null) 'target_date': targetDate,
      if (categoryId != null) 'category_id': categoryId,
      if (routineId != null) 'routine_id': routineId,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (hasTime != null) 'has_time': hasTime,
      if (startDateTime != null) 'start_date_time': startDateTime,
      if (endDateTime != null) 'end_date_time': endDateTime,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<TaskKind>? kind,
      Value<DateTime>? targetDate,
      Value<String?>? categoryId,
      Value<String?>? routineId,
      Value<bool>? isCompleted,
      Value<bool>? hasTime,
      Value<DateTime?>? startDateTime,
      Value<DateTime?>? endDateTime,
      Value<bool>? isAllDay,
      Value<bool>? isRecurring,
      Value<String?>? recurrenceRule,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TaskTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      targetDate: targetDate ?? this.targetDate,
      categoryId: categoryId ?? this.categoryId,
      routineId: routineId ?? this.routineId,
      isCompleted: isCompleted ?? this.isCompleted,
      hasTime: hasTime ?? this.hasTime,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      isAllDay: isAllDay ?? this.isAllDay,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($TaskTableTable.$converterkind.toSql(kind.value));
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (hasTime.present) {
      map['has_time'] = Variable<bool>(hasTime.value);
    }
    if (startDateTime.present) {
      map['start_date_time'] = Variable<DateTime>(startDateTime.value);
    }
    if (endDateTime.present) {
      map['end_date_time'] = Variable<DateTime>(endDateTime.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('targetDate: $targetDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('routineId: $routineId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('hasTime: $hasTime, ')
          ..write('startDateTime: $startDateTime, ')
          ..write('endDateTime: $endDateTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineTableTable extends RoutineTable
    with TableInfo<$RoutineTableTable, RoutineTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
      'end_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _frequencyMeta =
      const VerificationMeta('frequency');
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
      'frequency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _creationModeMeta =
      const VerificationMeta('creationMode');
  @override
  late final GeneratedColumn<String> creationMode = GeneratedColumn<String>(
      'creation_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intervalMeta =
      const VerificationMeta('interval');
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
      'interval', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _customUnitMeta =
      const VerificationMeta('customUnit');
  @override
  late final GeneratedColumn<String> customUnit = GeneratedColumn<String>(
      'custom_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weekdaysMeta =
      const VerificationMeta('weekdays');
  @override
  late final GeneratedColumn<String> weekdays = GeneratedColumn<String>(
      'weekdays', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _hasTimeMeta =
      const VerificationMeta('hasTime');
  @override
  late final GeneratedColumn<bool> hasTime = GeneratedColumn<bool>(
      'has_time', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("has_time" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isAllDayMeta =
      const VerificationMeta('isAllDay');
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
      'is_all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _startMinuteMeta =
      const VerificationMeta('startMinute');
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
      'start_minute', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _endMinuteMeta =
      const VerificationMeta('endMinute');
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
      'end_minute', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        kind,
        categoryId,
        startDate,
        endDate,
        frequency,
        creationMode,
        interval,
        customUnit,
        weekdays,
        hasTime,
        isAllDay,
        startMinute,
        endMinute,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    }
    if (data.containsKey('frequency')) {
      context.handle(_frequencyMeta,
          frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta));
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('creation_mode')) {
      context.handle(
          _creationModeMeta,
          creationMode.isAcceptableOrUnknown(
              data['creation_mode']!, _creationModeMeta));
    } else if (isInserting) {
      context.missing(_creationModeMeta);
    }
    if (data.containsKey('interval')) {
      context.handle(_intervalMeta,
          interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta));
    }
    if (data.containsKey('custom_unit')) {
      context.handle(
          _customUnitMeta,
          customUnit.isAcceptableOrUnknown(
              data['custom_unit']!, _customUnitMeta));
    }
    if (data.containsKey('weekdays')) {
      context.handle(_weekdaysMeta,
          weekdays.isAcceptableOrUnknown(data['weekdays']!, _weekdaysMeta));
    }
    if (data.containsKey('has_time')) {
      context.handle(_hasTimeMeta,
          hasTime.isAcceptableOrUnknown(data['has_time']!, _hasTimeMeta));
    }
    if (data.containsKey('is_all_day')) {
      context.handle(_isAllDayMeta,
          isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta));
    }
    if (data.containsKey('start_minute')) {
      context.handle(
          _startMinuteMeta,
          startMinute.isAcceptableOrUnknown(
              data['start_minute']!, _startMinuteMeta));
    }
    if (data.containsKey('end_minute')) {
      context.handle(_endMinuteMeta,
          endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_date']),
      frequency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}frequency'])!,
      creationMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}creation_mode'])!,
      interval: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval'])!,
      customUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_unit']),
      weekdays: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weekdays'])!,
      hasTime: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_time'])!,
      isAllDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_all_day'])!,
      startMinute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_minute']),
      endMinute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_minute']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RoutineTableTable createAlias(String alias) {
    return $RoutineTableTable(attachedDatabase, alias);
  }
}

class RoutineTableData extends DataClass
    implements Insertable<RoutineTableData> {
  final String id;
  final String title;
  final String kind;
  final String? categoryId;
  final DateTime startDate;
  final DateTime? endDate;
  final String frequency;
  final String creationMode;
  final int interval;
  final String? customUnit;
  final String weekdays;
  final bool hasTime;
  final bool isAllDay;
  final int? startMinute;
  final int? endMinute;
  final DateTime createdAt;
  const RoutineTableData(
      {required this.id,
      required this.title,
      required this.kind,
      this.categoryId,
      required this.startDate,
      this.endDate,
      required this.frequency,
      required this.creationMode,
      required this.interval,
      this.customUnit,
      required this.weekdays,
      required this.hasTime,
      required this.isAllDay,
      this.startMinute,
      this.endMinute,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['frequency'] = Variable<String>(frequency);
    map['creation_mode'] = Variable<String>(creationMode);
    map['interval'] = Variable<int>(interval);
    if (!nullToAbsent || customUnit != null) {
      map['custom_unit'] = Variable<String>(customUnit);
    }
    map['weekdays'] = Variable<String>(weekdays);
    map['has_time'] = Variable<bool>(hasTime);
    map['is_all_day'] = Variable<bool>(isAllDay);
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || endMinute != null) {
      map['end_minute'] = Variable<int>(endMinute);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RoutineTableCompanion toCompanion(bool nullToAbsent) {
    return RoutineTableCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      frequency: Value(frequency),
      creationMode: Value(creationMode),
      interval: Value(interval),
      customUnit: customUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(customUnit),
      weekdays: Value(weekdays),
      hasTime: Value(hasTime),
      isAllDay: Value(isAllDay),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      endMinute: endMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinute),
      createdAt: Value(createdAt),
    );
  }

  factory RoutineTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: serializer.fromJson<String>(json['kind']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      frequency: serializer.fromJson<String>(json['frequency']),
      creationMode: serializer.fromJson<String>(json['creationMode']),
      interval: serializer.fromJson<int>(json['interval']),
      customUnit: serializer.fromJson<String?>(json['customUnit']),
      weekdays: serializer.fromJson<String>(json['weekdays']),
      hasTime: serializer.fromJson<bool>(json['hasTime']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      endMinute: serializer.fromJson<int?>(json['endMinute']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(kind),
      'categoryId': serializer.toJson<String?>(categoryId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'frequency': serializer.toJson<String>(frequency),
      'creationMode': serializer.toJson<String>(creationMode),
      'interval': serializer.toJson<int>(interval),
      'customUnit': serializer.toJson<String?>(customUnit),
      'weekdays': serializer.toJson<String>(weekdays),
      'hasTime': serializer.toJson<bool>(hasTime),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'startMinute': serializer.toJson<int?>(startMinute),
      'endMinute': serializer.toJson<int?>(endMinute),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RoutineTableData copyWith(
          {String? id,
          String? title,
          String? kind,
          Value<String?> categoryId = const Value.absent(),
          DateTime? startDate,
          Value<DateTime?> endDate = const Value.absent(),
          String? frequency,
          String? creationMode,
          int? interval,
          Value<String?> customUnit = const Value.absent(),
          String? weekdays,
          bool? hasTime,
          bool? isAllDay,
          Value<int?> startMinute = const Value.absent(),
          Value<int?> endMinute = const Value.absent(),
          DateTime? createdAt}) =>
      RoutineTableData(
        id: id ?? this.id,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        startDate: startDate ?? this.startDate,
        endDate: endDate.present ? endDate.value : this.endDate,
        frequency: frequency ?? this.frequency,
        creationMode: creationMode ?? this.creationMode,
        interval: interval ?? this.interval,
        customUnit: customUnit.present ? customUnit.value : this.customUnit,
        weekdays: weekdays ?? this.weekdays,
        hasTime: hasTime ?? this.hasTime,
        isAllDay: isAllDay ?? this.isAllDay,
        startMinute: startMinute.present ? startMinute.value : this.startMinute,
        endMinute: endMinute.present ? endMinute.value : this.endMinute,
        createdAt: createdAt ?? this.createdAt,
      );
  RoutineTableData copyWithCompanion(RoutineTableCompanion data) {
    return RoutineTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      creationMode: data.creationMode.present
          ? data.creationMode.value
          : this.creationMode,
      interval: data.interval.present ? data.interval.value : this.interval,
      customUnit:
          data.customUnit.present ? data.customUnit.value : this.customUnit,
      weekdays: data.weekdays.present ? data.weekdays.value : this.weekdays,
      hasTime: data.hasTime.present ? data.hasTime.value : this.hasTime,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      startMinute:
          data.startMinute.present ? data.startMinute.value : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('frequency: $frequency, ')
          ..write('creationMode: $creationMode, ')
          ..write('interval: $interval, ')
          ..write('customUnit: $customUnit, ')
          ..write('weekdays: $weekdays, ')
          ..write('hasTime: $hasTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      kind,
      categoryId,
      startDate,
      endDate,
      frequency,
      creationMode,
      interval,
      customUnit,
      weekdays,
      hasTime,
      isAllDay,
      startMinute,
      endMinute,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.categoryId == this.categoryId &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.frequency == this.frequency &&
          other.creationMode == this.creationMode &&
          other.interval == this.interval &&
          other.customUnit == this.customUnit &&
          other.weekdays == this.weekdays &&
          other.hasTime == this.hasTime &&
          other.isAllDay == this.isAllDay &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.createdAt == this.createdAt);
}

class RoutineTableCompanion extends UpdateCompanion<RoutineTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> kind;
  final Value<String?> categoryId;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String> frequency;
  final Value<String> creationMode;
  final Value<int> interval;
  final Value<String?> customUnit;
  final Value<String> weekdays;
  final Value<bool> hasTime;
  final Value<bool> isAllDay;
  final Value<int?> startMinute;
  final Value<int?> endMinute;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RoutineTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.frequency = const Value.absent(),
    this.creationMode = const Value.absent(),
    this.interval = const Value.absent(),
    this.customUnit = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineTableCompanion.insert({
    required String id,
    required String title,
    required String kind,
    this.categoryId = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    required String frequency,
    required String creationMode,
    this.interval = const Value.absent(),
    this.customUnit = const Value.absent(),
    this.weekdays = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        kind = Value(kind),
        startDate = Value(startDate),
        frequency = Value(frequency),
        creationMode = Value(creationMode);
  static Insertable<RoutineTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<String>? categoryId,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? frequency,
    Expression<String>? creationMode,
    Expression<int>? interval,
    Expression<String>? customUnit,
    Expression<String>? weekdays,
    Expression<bool>? hasTime,
    Expression<bool>? isAllDay,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (categoryId != null) 'category_id': categoryId,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (frequency != null) 'frequency': frequency,
      if (creationMode != null) 'creation_mode': creationMode,
      if (interval != null) 'interval': interval,
      if (customUnit != null) 'custom_unit': customUnit,
      if (weekdays != null) 'weekdays': weekdays,
      if (hasTime != null) 'has_time': hasTime,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? kind,
      Value<String?>? categoryId,
      Value<DateTime>? startDate,
      Value<DateTime?>? endDate,
      Value<String>? frequency,
      Value<String>? creationMode,
      Value<int>? interval,
      Value<String?>? customUnit,
      Value<String>? weekdays,
      Value<bool>? hasTime,
      Value<bool>? isAllDay,
      Value<int?>? startMinute,
      Value<int?>? endMinute,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return RoutineTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      frequency: frequency ?? this.frequency,
      creationMode: creationMode ?? this.creationMode,
      interval: interval ?? this.interval,
      customUnit: customUnit ?? this.customUnit,
      weekdays: weekdays ?? this.weekdays,
      hasTime: hasTime ?? this.hasTime,
      isAllDay: isAllDay ?? this.isAllDay,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (creationMode.present) {
      map['creation_mode'] = Variable<String>(creationMode.value);
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (customUnit.present) {
      map['custom_unit'] = Variable<String>(customUnit.value);
    }
    if (weekdays.present) {
      map['weekdays'] = Variable<String>(weekdays.value);
    }
    if (hasTime.present) {
      map['has_time'] = Variable<bool>(hasTime.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('categoryId: $categoryId, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('frequency: $frequency, ')
          ..write('creationMode: $creationMode, ')
          ..write('interval: $interval, ')
          ..write('customUnit: $customUnit, ')
          ..write('weekdays: $weekdays, ')
          ..write('hasTime: $hasTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoryTableTable categoryTable = $CategoryTableTable(this);
  late final $TaskTableTable taskTable = $TaskTableTable(this);
  late final $RoutineTableTable routineTable = $RoutineTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [categoryTable, taskTable, routineTable];
}

typedef $$CategoryTableTableCreateCompanionBuilder = CategoryTableCompanion
    Function({
  required String id,
  required String name,
  required int color,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$CategoryTableTableUpdateCompanionBuilder = CategoryTableCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<int> color,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$CategoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryTableTable> {
  $$CategoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));
}

class $$CategoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryTableTable> {
  $$CategoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryTableTable> {
  $$CategoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CategoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryTableTable,
    CategoryTableData,
    $$CategoryTableTableFilterComposer,
    $$CategoryTableTableOrderingComposer,
    $$CategoryTableTableAnnotationComposer,
    $$CategoryTableTableCreateCompanionBuilder,
    $$CategoryTableTableUpdateCompanionBuilder,
    (
      CategoryTableData,
      BaseReferences<_$AppDatabase, $CategoryTableTable, CategoryTableData>
    ),
    CategoryTableData,
    PrefetchHooks Function()> {
  $$CategoryTableTableTableManager(_$AppDatabase db, $CategoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryTableCompanion(
            id: id,
            name: name,
            color: color,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int color,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryTableCompanion.insert(
            id: id,
            name: name,
            color: color,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoryTableTable,
    CategoryTableData,
    $$CategoryTableTableFilterComposer,
    $$CategoryTableTableOrderingComposer,
    $$CategoryTableTableAnnotationComposer,
    $$CategoryTableTableCreateCompanionBuilder,
    $$CategoryTableTableUpdateCompanionBuilder,
    (
      CategoryTableData,
      BaseReferences<_$AppDatabase, $CategoryTableTable, CategoryTableData>
    ),
    CategoryTableData,
    PrefetchHooks Function()>;
typedef $$TaskTableTableCreateCompanionBuilder = TaskTableCompanion Function({
  required String id,
  required String title,
  Value<TaskKind> kind,
  Value<DateTime> targetDate,
  Value<String?> categoryId,
  Value<String?> routineId,
  Value<bool> isCompleted,
  Value<bool> hasTime,
  Value<DateTime?> startDateTime,
  Value<DateTime?> endDateTime,
  Value<bool> isAllDay,
  Value<bool> isRecurring,
  Value<String?> recurrenceRule,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TaskTableTableUpdateCompanionBuilder = TaskTableCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<TaskKind> kind,
  Value<DateTime> targetDate,
  Value<String?> categoryId,
  Value<String?> routineId,
  Value<bool> isCompleted,
  Value<bool> hasTime,
  Value<DateTime?> startDateTime,
  Value<DateTime?> endDateTime,
  Value<bool> isAllDay,
  Value<bool> isRecurring,
  Value<String?> recurrenceRule,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TaskTableTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTableTable> {
  $$TaskTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TaskKind, TaskKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasTime => $composableBuilder(
      column: $table.hasTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDateTime => $composableBuilder(
      column: $table.startDateTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDateTime => $composableBuilder(
      column: $table.endDateTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAllDay => $composableBuilder(
      column: $table.isAllDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TaskTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTableTable> {
  $$TaskTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasTime => $composableBuilder(
      column: $table.hasTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDateTime => $composableBuilder(
      column: $table.startDateTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDateTime => $composableBuilder(
      column: $table.endDateTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
      column: $table.isAllDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TaskTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTableTable> {
  $$TaskTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<bool> get hasTime =>
      $composableBuilder(column: $table.hasTime, builder: (column) => column);

  GeneratedColumn<DateTime> get startDateTime => $composableBuilder(
      column: $table.startDateTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endDateTime => $composableBuilder(
      column: $table.endDateTime, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
      column: $table.isRecurring, builder: (column) => column);

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
      column: $table.recurrenceRule, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TaskTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TaskTableTable,
    TaskTableData,
    $$TaskTableTableFilterComposer,
    $$TaskTableTableOrderingComposer,
    $$TaskTableTableAnnotationComposer,
    $$TaskTableTableCreateCompanionBuilder,
    $$TaskTableTableUpdateCompanionBuilder,
    (
      TaskTableData,
      BaseReferences<_$AppDatabase, $TaskTableTable, TaskTableData>
    ),
    TaskTableData,
    PrefetchHooks Function()> {
  $$TaskTableTableTableManager(_$AppDatabase db, $TaskTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<TaskKind> kind = const Value.absent(),
            Value<DateTime> targetDate = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<bool> hasTime = const Value.absent(),
            Value<DateTime?> startDateTime = const Value.absent(),
            Value<DateTime?> endDateTime = const Value.absent(),
            Value<bool> isAllDay = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<String?> recurrenceRule = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskTableCompanion(
            id: id,
            title: title,
            kind: kind,
            targetDate: targetDate,
            categoryId: categoryId,
            routineId: routineId,
            isCompleted: isCompleted,
            hasTime: hasTime,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            isAllDay: isAllDay,
            isRecurring: isRecurring,
            recurrenceRule: recurrenceRule,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<TaskKind> kind = const Value.absent(),
            Value<DateTime> targetDate = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<bool> hasTime = const Value.absent(),
            Value<DateTime?> startDateTime = const Value.absent(),
            Value<DateTime?> endDateTime = const Value.absent(),
            Value<bool> isAllDay = const Value.absent(),
            Value<bool> isRecurring = const Value.absent(),
            Value<String?> recurrenceRule = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskTableCompanion.insert(
            id: id,
            title: title,
            kind: kind,
            targetDate: targetDate,
            categoryId: categoryId,
            routineId: routineId,
            isCompleted: isCompleted,
            hasTime: hasTime,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            isAllDay: isAllDay,
            isRecurring: isRecurring,
            recurrenceRule: recurrenceRule,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TaskTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TaskTableTable,
    TaskTableData,
    $$TaskTableTableFilterComposer,
    $$TaskTableTableOrderingComposer,
    $$TaskTableTableAnnotationComposer,
    $$TaskTableTableCreateCompanionBuilder,
    $$TaskTableTableUpdateCompanionBuilder,
    (
      TaskTableData,
      BaseReferences<_$AppDatabase, $TaskTableTable, TaskTableData>
    ),
    TaskTableData,
    PrefetchHooks Function()>;
typedef $$RoutineTableTableCreateCompanionBuilder = RoutineTableCompanion
    Function({
  required String id,
  required String title,
  required String kind,
  Value<String?> categoryId,
  required DateTime startDate,
  Value<DateTime?> endDate,
  required String frequency,
  required String creationMode,
  Value<int> interval,
  Value<String?> customUnit,
  Value<String> weekdays,
  Value<bool> hasTime,
  Value<bool> isAllDay,
  Value<int?> startMinute,
  Value<int?> endMinute,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$RoutineTableTableUpdateCompanionBuilder = RoutineTableCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String> kind,
  Value<String?> categoryId,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<String> frequency,
  Value<String> creationMode,
  Value<int> interval,
  Value<String?> customUnit,
  Value<String> weekdays,
  Value<bool> hasTime,
  Value<bool> isAllDay,
  Value<int?> startMinute,
  Value<int?> endMinute,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$RoutineTableTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineTableTable> {
  $$RoutineTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get creationMode => $composableBuilder(
      column: $table.creationMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customUnit => $composableBuilder(
      column: $table.customUnit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekdays => $composableBuilder(
      column: $table.weekdays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasTime => $composableBuilder(
      column: $table.hasTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isAllDay => $composableBuilder(
      column: $table.isAllDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMinute => $composableBuilder(
      column: $table.startMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endMinute => $composableBuilder(
      column: $table.endMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$RoutineTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineTableTable> {
  $$RoutineTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get frequency => $composableBuilder(
      column: $table.frequency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get creationMode => $composableBuilder(
      column: $table.creationMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customUnit => $composableBuilder(
      column: $table.customUnit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekdays => $composableBuilder(
      column: $table.weekdays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasTime => $composableBuilder(
      column: $table.hasTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
      column: $table.isAllDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMinute => $composableBuilder(
      column: $table.startMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endMinute => $composableBuilder(
      column: $table.endMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$RoutineTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineTableTable> {
  $$RoutineTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get creationMode => $composableBuilder(
      column: $table.creationMode, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<String> get customUnit => $composableBuilder(
      column: $table.customUnit, builder: (column) => column);

  GeneratedColumn<String> get weekdays =>
      $composableBuilder(column: $table.weekdays, builder: (column) => column);

  GeneratedColumn<bool> get hasTime =>
      $composableBuilder(column: $table.hasTime, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
      column: $table.startMinute, builder: (column) => column);

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RoutineTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutineTableTable,
    RoutineTableData,
    $$RoutineTableTableFilterComposer,
    $$RoutineTableTableOrderingComposer,
    $$RoutineTableTableAnnotationComposer,
    $$RoutineTableTableCreateCompanionBuilder,
    $$RoutineTableTableUpdateCompanionBuilder,
    (
      RoutineTableData,
      BaseReferences<_$AppDatabase, $RoutineTableTable, RoutineTableData>
    ),
    RoutineTableData,
    PrefetchHooks Function()> {
  $$RoutineTableTableTableManager(_$AppDatabase db, $RoutineTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<DateTime?> endDate = const Value.absent(),
            Value<String> frequency = const Value.absent(),
            Value<String> creationMode = const Value.absent(),
            Value<int> interval = const Value.absent(),
            Value<String?> customUnit = const Value.absent(),
            Value<String> weekdays = const Value.absent(),
            Value<bool> hasTime = const Value.absent(),
            Value<bool> isAllDay = const Value.absent(),
            Value<int?> startMinute = const Value.absent(),
            Value<int?> endMinute = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineTableCompanion(
            id: id,
            title: title,
            kind: kind,
            categoryId: categoryId,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency,
            creationMode: creationMode,
            interval: interval,
            customUnit: customUnit,
            weekdays: weekdays,
            hasTime: hasTime,
            isAllDay: isAllDay,
            startMinute: startMinute,
            endMinute: endMinute,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String kind,
            Value<String?> categoryId = const Value.absent(),
            required DateTime startDate,
            Value<DateTime?> endDate = const Value.absent(),
            required String frequency,
            required String creationMode,
            Value<int> interval = const Value.absent(),
            Value<String?> customUnit = const Value.absent(),
            Value<String> weekdays = const Value.absent(),
            Value<bool> hasTime = const Value.absent(),
            Value<bool> isAllDay = const Value.absent(),
            Value<int?> startMinute = const Value.absent(),
            Value<int?> endMinute = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineTableCompanion.insert(
            id: id,
            title: title,
            kind: kind,
            categoryId: categoryId,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency,
            creationMode: creationMode,
            interval: interval,
            customUnit: customUnit,
            weekdays: weekdays,
            hasTime: hasTime,
            isAllDay: isAllDay,
            startMinute: startMinute,
            endMinute: endMinute,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RoutineTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutineTableTable,
    RoutineTableData,
    $$RoutineTableTableFilterComposer,
    $$RoutineTableTableOrderingComposer,
    $$RoutineTableTableAnnotationComposer,
    $$RoutineTableTableCreateCompanionBuilder,
    $$RoutineTableTableUpdateCompanionBuilder,
    (
      RoutineTableData,
      BaseReferences<_$AppDatabase, $RoutineTableTable, RoutineTableData>
    ),
    RoutineTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoryTableTableTableManager get categoryTable =>
      $$CategoryTableTableTableManager(_db, _db.categoryTable);
  $$TaskTableTableTableManager get taskTable =>
      $$TaskTableTableTableManager(_db, _db.taskTable);
  $$RoutineTableTableTableManager get routineTable =>
      $$RoutineTableTableTableManager(_db, _db.routineTable);
}

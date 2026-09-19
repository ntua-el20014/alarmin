// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, emoji, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
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
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Category(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Category copyWith(
          {String? id,
          String? name,
          String? emoji,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, emoji, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String emoji,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        emoji = Value(emoji),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? emoji,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmsTable extends Alarms with TableInfo<$AlarmsTable, Alarm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scheduleTypeMeta =
      const VerificationMeta('scheduleType');
  @override
  late final GeneratedColumn<int> scheduleType = GeneratedColumn<int>(
      'schedule_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timeOfDayMeta =
      const VerificationMeta('timeOfDay');
  @override
  late final GeneratedColumn<int> timeOfDay = GeneratedColumn<int>(
      'time_of_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _scheduledDateMeta =
      const VerificationMeta('scheduledDate');
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>('scheduled_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
      'interval_days', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _scheduleStartDateMeta =
      const VerificationMeta('scheduleStartDate');
  @override
  late final GeneratedColumn<DateTime> scheduleStartDate =
      GeneratedColumn<DateTime>('schedule_start_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _scheduleEndDateMeta =
      const VerificationMeta('scheduleEndDate');
  @override
  late final GeneratedColumn<DateTime> scheduleEndDate =
      GeneratedColumn<DateTime>('schedule_end_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'));
  static const VerificationMeta _deleteAfterUseMeta =
      const VerificationMeta('deleteAfterUse');
  @override
  late final GeneratedColumn<bool> deleteAfterUse = GeneratedColumn<bool>(
      'delete_after_use', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("delete_after_use" IN (0, 1))'));
  static const VerificationMeta _ringtoneMeta =
      const VerificationMeta('ringtone');
  @override
  late final GeneratedColumn<String> ringtone = GeneratedColumn<String>(
      'ringtone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vibrationMeta =
      const VerificationMeta('vibration');
  @override
  late final GeneratedColumn<int> vibration = GeneratedColumn<int>(
      'vibration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _snoozeDurationSecondsMeta =
      const VerificationMeta('snoozeDurationSeconds');
  @override
  late final GeneratedColumn<int> snoozeDurationSeconds = GeneratedColumn<int>(
      'snooze_duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reincarnationCountMeta =
      const VerificationMeta('reincarnationCount');
  @override
  late final GeneratedColumn<int> reincarnationCount = GeneratedColumn<int>(
      'reincarnation_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reincarnationIntervalSecondsMeta =
      const VerificationMeta('reincarnationIntervalSeconds');
  @override
  late final GeneratedColumn<int> reincarnationIntervalSeconds =
      GeneratedColumn<int>('reincarnation_interval_seconds', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _nextOccurrenceAtMeta =
      const VerificationMeta('nextOccurrenceAt');
  @override
  late final GeneratedColumn<DateTime> nextOccurrenceAt =
      GeneratedColumn<DateTime>('next_occurrence_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        categoryId,
        scheduleType,
        timeOfDay,
        scheduledDate,
        intervalDays,
        scheduleStartDate,
        scheduleEndDate,
        isEnabled,
        deleteAfterUse,
        ringtone,
        vibration,
        snoozeDurationSeconds,
        reincarnationCount,
        reincarnationIntervalSeconds,
        createdAt,
        updatedAt,
        nextOccurrenceAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarms';
  @override
  VerificationContext validateIntegrity(Insertable<Alarm> instance,
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
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('schedule_type')) {
      context.handle(
          _scheduleTypeMeta,
          scheduleType.isAcceptableOrUnknown(
              data['schedule_type']!, _scheduleTypeMeta));
    } else if (isInserting) {
      context.missing(_scheduleTypeMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
          _timeOfDayMeta,
          timeOfDay.isAcceptableOrUnknown(
              data['time_of_day']!, _timeOfDayMeta));
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
          _scheduledDateMeta,
          scheduledDate.isAcceptableOrUnknown(
              data['scheduled_date']!, _scheduledDateMeta));
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    }
    if (data.containsKey('schedule_start_date')) {
      context.handle(
          _scheduleStartDateMeta,
          scheduleStartDate.isAcceptableOrUnknown(
              data['schedule_start_date']!, _scheduleStartDateMeta));
    }
    if (data.containsKey('schedule_end_date')) {
      context.handle(
          _scheduleEndDateMeta,
          scheduleEndDate.isAcceptableOrUnknown(
              data['schedule_end_date']!, _scheduleEndDateMeta));
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
    } else if (isInserting) {
      context.missing(_isEnabledMeta);
    }
    if (data.containsKey('delete_after_use')) {
      context.handle(
          _deleteAfterUseMeta,
          deleteAfterUse.isAcceptableOrUnknown(
              data['delete_after_use']!, _deleteAfterUseMeta));
    } else if (isInserting) {
      context.missing(_deleteAfterUseMeta);
    }
    if (data.containsKey('ringtone')) {
      context.handle(_ringtoneMeta,
          ringtone.isAcceptableOrUnknown(data['ringtone']!, _ringtoneMeta));
    } else if (isInserting) {
      context.missing(_ringtoneMeta);
    }
    if (data.containsKey('vibration')) {
      context.handle(_vibrationMeta,
          vibration.isAcceptableOrUnknown(data['vibration']!, _vibrationMeta));
    } else if (isInserting) {
      context.missing(_vibrationMeta);
    }
    if (data.containsKey('snooze_duration_seconds')) {
      context.handle(
          _snoozeDurationSecondsMeta,
          snoozeDurationSeconds.isAcceptableOrUnknown(
              data['snooze_duration_seconds']!, _snoozeDurationSecondsMeta));
    } else if (isInserting) {
      context.missing(_snoozeDurationSecondsMeta);
    }
    if (data.containsKey('reincarnation_count')) {
      context.handle(
          _reincarnationCountMeta,
          reincarnationCount.isAcceptableOrUnknown(
              data['reincarnation_count']!, _reincarnationCountMeta));
    } else if (isInserting) {
      context.missing(_reincarnationCountMeta);
    }
    if (data.containsKey('reincarnation_interval_seconds')) {
      context.handle(
          _reincarnationIntervalSecondsMeta,
          reincarnationIntervalSeconds.isAcceptableOrUnknown(
              data['reincarnation_interval_seconds']!,
              _reincarnationIntervalSecondsMeta));
    } else if (isInserting) {
      context.missing(_reincarnationIntervalSecondsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('next_occurrence_at')) {
      context.handle(
          _nextOccurrenceAtMeta,
          nextOccurrenceAt.isAcceptableOrUnknown(
              data['next_occurrence_at']!, _nextOccurrenceAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alarm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alarm(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      scheduleType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}schedule_type'])!,
      timeOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_of_day'])!,
      scheduledDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}scheduled_date']),
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_days']),
      scheduleStartDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}schedule_start_date']),
      scheduleEndDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}schedule_end_date']),
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
      deleteAfterUse: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}delete_after_use'])!,
      ringtone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ringtone'])!,
      vibration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}vibration'])!,
      snoozeDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}snooze_duration_seconds'])!,
      reincarnationCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}reincarnation_count'])!,
      reincarnationIntervalSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}reincarnation_interval_seconds'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      nextOccurrenceAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_occurrence_at']),
    );
  }

  @override
  $AlarmsTable createAlias(String alias) {
    return $AlarmsTable(attachedDatabase, alias);
  }
}

class Alarm extends DataClass implements Insertable<Alarm> {
  final String id;
  final String title;
  final String? categoryId;
  final int scheduleType;
  final int timeOfDay;
  final DateTime? scheduledDate;
  final int? intervalDays;
  final DateTime? scheduleStartDate;
  final DateTime? scheduleEndDate;
  final bool isEnabled;
  final bool deleteAfterUse;
  final String ringtone;
  final int vibration;
  final int snoozeDurationSeconds;
  final int reincarnationCount;
  final int reincarnationIntervalSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextOccurrenceAt;
  const Alarm(
      {required this.id,
      required this.title,
      this.categoryId,
      required this.scheduleType,
      required this.timeOfDay,
      this.scheduledDate,
      this.intervalDays,
      this.scheduleStartDate,
      this.scheduleEndDate,
      required this.isEnabled,
      required this.deleteAfterUse,
      required this.ringtone,
      required this.vibration,
      required this.snoozeDurationSeconds,
      required this.reincarnationCount,
      required this.reincarnationIntervalSeconds,
      required this.createdAt,
      required this.updatedAt,
      this.nextOccurrenceAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['schedule_type'] = Variable<int>(scheduleType);
    map['time_of_day'] = Variable<int>(timeOfDay);
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    if (!nullToAbsent || scheduleStartDate != null) {
      map['schedule_start_date'] = Variable<DateTime>(scheduleStartDate);
    }
    if (!nullToAbsent || scheduleEndDate != null) {
      map['schedule_end_date'] = Variable<DateTime>(scheduleEndDate);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['delete_after_use'] = Variable<bool>(deleteAfterUse);
    map['ringtone'] = Variable<String>(ringtone);
    map['vibration'] = Variable<int>(vibration);
    map['snooze_duration_seconds'] = Variable<int>(snoozeDurationSeconds);
    map['reincarnation_count'] = Variable<int>(reincarnationCount);
    map['reincarnation_interval_seconds'] =
        Variable<int>(reincarnationIntervalSeconds);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || nextOccurrenceAt != null) {
      map['next_occurrence_at'] = Variable<DateTime>(nextOccurrenceAt);
    }
    return map;
  }

  AlarmsCompanion toCompanion(bool nullToAbsent) {
    return AlarmsCompanion(
      id: Value(id),
      title: Value(title),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      scheduleType: Value(scheduleType),
      timeOfDay: Value(timeOfDay),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      scheduleStartDate: scheduleStartDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleStartDate),
      scheduleEndDate: scheduleEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduleEndDate),
      isEnabled: Value(isEnabled),
      deleteAfterUse: Value(deleteAfterUse),
      ringtone: Value(ringtone),
      vibration: Value(vibration),
      snoozeDurationSeconds: Value(snoozeDurationSeconds),
      reincarnationCount: Value(reincarnationCount),
      reincarnationIntervalSeconds: Value(reincarnationIntervalSeconds),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      nextOccurrenceAt: nextOccurrenceAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextOccurrenceAt),
    );
  }

  factory Alarm.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alarm(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      scheduleType: serializer.fromJson<int>(json['scheduleType']),
      timeOfDay: serializer.fromJson<int>(json['timeOfDay']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      scheduleStartDate:
          serializer.fromJson<DateTime?>(json['scheduleStartDate']),
      scheduleEndDate: serializer.fromJson<DateTime?>(json['scheduleEndDate']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      deleteAfterUse: serializer.fromJson<bool>(json['deleteAfterUse']),
      ringtone: serializer.fromJson<String>(json['ringtone']),
      vibration: serializer.fromJson<int>(json['vibration']),
      snoozeDurationSeconds:
          serializer.fromJson<int>(json['snoozeDurationSeconds']),
      reincarnationCount: serializer.fromJson<int>(json['reincarnationCount']),
      reincarnationIntervalSeconds:
          serializer.fromJson<int>(json['reincarnationIntervalSeconds']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      nextOccurrenceAt:
          serializer.fromJson<DateTime?>(json['nextOccurrenceAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'categoryId': serializer.toJson<String?>(categoryId),
      'scheduleType': serializer.toJson<int>(scheduleType),
      'timeOfDay': serializer.toJson<int>(timeOfDay),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'scheduleStartDate': serializer.toJson<DateTime?>(scheduleStartDate),
      'scheduleEndDate': serializer.toJson<DateTime?>(scheduleEndDate),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'deleteAfterUse': serializer.toJson<bool>(deleteAfterUse),
      'ringtone': serializer.toJson<String>(ringtone),
      'vibration': serializer.toJson<int>(vibration),
      'snoozeDurationSeconds': serializer.toJson<int>(snoozeDurationSeconds),
      'reincarnationCount': serializer.toJson<int>(reincarnationCount),
      'reincarnationIntervalSeconds':
          serializer.toJson<int>(reincarnationIntervalSeconds),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'nextOccurrenceAt': serializer.toJson<DateTime?>(nextOccurrenceAt),
    };
  }

  Alarm copyWith(
          {String? id,
          String? title,
          Value<String?> categoryId = const Value.absent(),
          int? scheduleType,
          int? timeOfDay,
          Value<DateTime?> scheduledDate = const Value.absent(),
          Value<int?> intervalDays = const Value.absent(),
          Value<DateTime?> scheduleStartDate = const Value.absent(),
          Value<DateTime?> scheduleEndDate = const Value.absent(),
          bool? isEnabled,
          bool? deleteAfterUse,
          String? ringtone,
          int? vibration,
          int? snoozeDurationSeconds,
          int? reincarnationCount,
          int? reincarnationIntervalSeconds,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> nextOccurrenceAt = const Value.absent()}) =>
      Alarm(
        id: id ?? this.id,
        title: title ?? this.title,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        scheduleType: scheduleType ?? this.scheduleType,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        scheduledDate:
            scheduledDate.present ? scheduledDate.value : this.scheduledDate,
        intervalDays:
            intervalDays.present ? intervalDays.value : this.intervalDays,
        scheduleStartDate: scheduleStartDate.present
            ? scheduleStartDate.value
            : this.scheduleStartDate,
        scheduleEndDate: scheduleEndDate.present
            ? scheduleEndDate.value
            : this.scheduleEndDate,
        isEnabled: isEnabled ?? this.isEnabled,
        deleteAfterUse: deleteAfterUse ?? this.deleteAfterUse,
        ringtone: ringtone ?? this.ringtone,
        vibration: vibration ?? this.vibration,
        snoozeDurationSeconds:
            snoozeDurationSeconds ?? this.snoozeDurationSeconds,
        reincarnationCount: reincarnationCount ?? this.reincarnationCount,
        reincarnationIntervalSeconds:
            reincarnationIntervalSeconds ?? this.reincarnationIntervalSeconds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        nextOccurrenceAt: nextOccurrenceAt.present
            ? nextOccurrenceAt.value
            : this.nextOccurrenceAt,
      );
  Alarm copyWithCompanion(AlarmsCompanion data) {
    return Alarm(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      scheduleType: data.scheduleType.present
          ? data.scheduleType.value
          : this.scheduleType,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      scheduleStartDate: data.scheduleStartDate.present
          ? data.scheduleStartDate.value
          : this.scheduleStartDate,
      scheduleEndDate: data.scheduleEndDate.present
          ? data.scheduleEndDate.value
          : this.scheduleEndDate,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      deleteAfterUse: data.deleteAfterUse.present
          ? data.deleteAfterUse.value
          : this.deleteAfterUse,
      ringtone: data.ringtone.present ? data.ringtone.value : this.ringtone,
      vibration: data.vibration.present ? data.vibration.value : this.vibration,
      snoozeDurationSeconds: data.snoozeDurationSeconds.present
          ? data.snoozeDurationSeconds.value
          : this.snoozeDurationSeconds,
      reincarnationCount: data.reincarnationCount.present
          ? data.reincarnationCount.value
          : this.reincarnationCount,
      reincarnationIntervalSeconds: data.reincarnationIntervalSeconds.present
          ? data.reincarnationIntervalSeconds.value
          : this.reincarnationIntervalSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      nextOccurrenceAt: data.nextOccurrenceAt.present
          ? data.nextOccurrenceAt.value
          : this.nextOccurrenceAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alarm(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('categoryId: $categoryId, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('scheduleStartDate: $scheduleStartDate, ')
          ..write('scheduleEndDate: $scheduleEndDate, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('deleteAfterUse: $deleteAfterUse, ')
          ..write('ringtone: $ringtone, ')
          ..write('vibration: $vibration, ')
          ..write('snoozeDurationSeconds: $snoozeDurationSeconds, ')
          ..write('reincarnationCount: $reincarnationCount, ')
          ..write(
              'reincarnationIntervalSeconds: $reincarnationIntervalSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextOccurrenceAt: $nextOccurrenceAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      categoryId,
      scheduleType,
      timeOfDay,
      scheduledDate,
      intervalDays,
      scheduleStartDate,
      scheduleEndDate,
      isEnabled,
      deleteAfterUse,
      ringtone,
      vibration,
      snoozeDurationSeconds,
      reincarnationCount,
      reincarnationIntervalSeconds,
      createdAt,
      updatedAt,
      nextOccurrenceAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alarm &&
          other.id == this.id &&
          other.title == this.title &&
          other.categoryId == this.categoryId &&
          other.scheduleType == this.scheduleType &&
          other.timeOfDay == this.timeOfDay &&
          other.scheduledDate == this.scheduledDate &&
          other.intervalDays == this.intervalDays &&
          other.scheduleStartDate == this.scheduleStartDate &&
          other.scheduleEndDate == this.scheduleEndDate &&
          other.isEnabled == this.isEnabled &&
          other.deleteAfterUse == this.deleteAfterUse &&
          other.ringtone == this.ringtone &&
          other.vibration == this.vibration &&
          other.snoozeDurationSeconds == this.snoozeDurationSeconds &&
          other.reincarnationCount == this.reincarnationCount &&
          other.reincarnationIntervalSeconds ==
              this.reincarnationIntervalSeconds &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.nextOccurrenceAt == this.nextOccurrenceAt);
}

class AlarmsCompanion extends UpdateCompanion<Alarm> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> categoryId;
  final Value<int> scheduleType;
  final Value<int> timeOfDay;
  final Value<DateTime?> scheduledDate;
  final Value<int?> intervalDays;
  final Value<DateTime?> scheduleStartDate;
  final Value<DateTime?> scheduleEndDate;
  final Value<bool> isEnabled;
  final Value<bool> deleteAfterUse;
  final Value<String> ringtone;
  final Value<int> vibration;
  final Value<int> snoozeDurationSeconds;
  final Value<int> reincarnationCount;
  final Value<int> reincarnationIntervalSeconds;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> nextOccurrenceAt;
  final Value<int> rowid;
  const AlarmsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.scheduleType = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.scheduleStartDate = const Value.absent(),
    this.scheduleEndDate = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.deleteAfterUse = const Value.absent(),
    this.ringtone = const Value.absent(),
    this.vibration = const Value.absent(),
    this.snoozeDurationSeconds = const Value.absent(),
    this.reincarnationCount = const Value.absent(),
    this.reincarnationIntervalSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.nextOccurrenceAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmsCompanion.insert({
    required String id,
    required String title,
    this.categoryId = const Value.absent(),
    required int scheduleType,
    required int timeOfDay,
    this.scheduledDate = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.scheduleStartDate = const Value.absent(),
    this.scheduleEndDate = const Value.absent(),
    required bool isEnabled,
    required bool deleteAfterUse,
    required String ringtone,
    required int vibration,
    required int snoozeDurationSeconds,
    required int reincarnationCount,
    required int reincarnationIntervalSeconds,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.nextOccurrenceAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        scheduleType = Value(scheduleType),
        timeOfDay = Value(timeOfDay),
        isEnabled = Value(isEnabled),
        deleteAfterUse = Value(deleteAfterUse),
        ringtone = Value(ringtone),
        vibration = Value(vibration),
        snoozeDurationSeconds = Value(snoozeDurationSeconds),
        reincarnationCount = Value(reincarnationCount),
        reincarnationIntervalSeconds = Value(reincarnationIntervalSeconds),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Alarm> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? categoryId,
    Expression<int>? scheduleType,
    Expression<int>? timeOfDay,
    Expression<DateTime>? scheduledDate,
    Expression<int>? intervalDays,
    Expression<DateTime>? scheduleStartDate,
    Expression<DateTime>? scheduleEndDate,
    Expression<bool>? isEnabled,
    Expression<bool>? deleteAfterUse,
    Expression<String>? ringtone,
    Expression<int>? vibration,
    Expression<int>? snoozeDurationSeconds,
    Expression<int>? reincarnationCount,
    Expression<int>? reincarnationIntervalSeconds,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? nextOccurrenceAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (categoryId != null) 'category_id': categoryId,
      if (scheduleType != null) 'schedule_type': scheduleType,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (scheduleStartDate != null) 'schedule_start_date': scheduleStartDate,
      if (scheduleEndDate != null) 'schedule_end_date': scheduleEndDate,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (deleteAfterUse != null) 'delete_after_use': deleteAfterUse,
      if (ringtone != null) 'ringtone': ringtone,
      if (vibration != null) 'vibration': vibration,
      if (snoozeDurationSeconds != null)
        'snooze_duration_seconds': snoozeDurationSeconds,
      if (reincarnationCount != null) 'reincarnation_count': reincarnationCount,
      if (reincarnationIntervalSeconds != null)
        'reincarnation_interval_seconds': reincarnationIntervalSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (nextOccurrenceAt != null) 'next_occurrence_at': nextOccurrenceAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? categoryId,
      Value<int>? scheduleType,
      Value<int>? timeOfDay,
      Value<DateTime?>? scheduledDate,
      Value<int?>? intervalDays,
      Value<DateTime?>? scheduleStartDate,
      Value<DateTime?>? scheduleEndDate,
      Value<bool>? isEnabled,
      Value<bool>? deleteAfterUse,
      Value<String>? ringtone,
      Value<int>? vibration,
      Value<int>? snoozeDurationSeconds,
      Value<int>? reincarnationCount,
      Value<int>? reincarnationIntervalSeconds,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? nextOccurrenceAt,
      Value<int>? rowid}) {
    return AlarmsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      scheduleType: scheduleType ?? this.scheduleType,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      intervalDays: intervalDays ?? this.intervalDays,
      scheduleStartDate: scheduleStartDate ?? this.scheduleStartDate,
      scheduleEndDate: scheduleEndDate ?? this.scheduleEndDate,
      isEnabled: isEnabled ?? this.isEnabled,
      deleteAfterUse: deleteAfterUse ?? this.deleteAfterUse,
      ringtone: ringtone ?? this.ringtone,
      vibration: vibration ?? this.vibration,
      snoozeDurationSeconds:
          snoozeDurationSeconds ?? this.snoozeDurationSeconds,
      reincarnationCount: reincarnationCount ?? this.reincarnationCount,
      reincarnationIntervalSeconds:
          reincarnationIntervalSeconds ?? this.reincarnationIntervalSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextOccurrenceAt: nextOccurrenceAt ?? this.nextOccurrenceAt,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (scheduleType.present) {
      map['schedule_type'] = Variable<int>(scheduleType.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<int>(timeOfDay.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (scheduleStartDate.present) {
      map['schedule_start_date'] = Variable<DateTime>(scheduleStartDate.value);
    }
    if (scheduleEndDate.present) {
      map['schedule_end_date'] = Variable<DateTime>(scheduleEndDate.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (deleteAfterUse.present) {
      map['delete_after_use'] = Variable<bool>(deleteAfterUse.value);
    }
    if (ringtone.present) {
      map['ringtone'] = Variable<String>(ringtone.value);
    }
    if (vibration.present) {
      map['vibration'] = Variable<int>(vibration.value);
    }
    if (snoozeDurationSeconds.present) {
      map['snooze_duration_seconds'] =
          Variable<int>(snoozeDurationSeconds.value);
    }
    if (reincarnationCount.present) {
      map['reincarnation_count'] = Variable<int>(reincarnationCount.value);
    }
    if (reincarnationIntervalSeconds.present) {
      map['reincarnation_interval_seconds'] =
          Variable<int>(reincarnationIntervalSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (nextOccurrenceAt.present) {
      map['next_occurrence_at'] = Variable<DateTime>(nextOccurrenceAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('categoryId: $categoryId, ')
          ..write('scheduleType: $scheduleType, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('scheduleStartDate: $scheduleStartDate, ')
          ..write('scheduleEndDate: $scheduleEndDate, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('deleteAfterUse: $deleteAfterUse, ')
          ..write('ringtone: $ringtone, ')
          ..write('vibration: $vibration, ')
          ..write('snoozeDurationSeconds: $snoozeDurationSeconds, ')
          ..write('reincarnationCount: $reincarnationCount, ')
          ..write(
              'reincarnationIntervalSeconds: $reincarnationIntervalSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextOccurrenceAt: $nextOccurrenceAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlarmWeekdaysTable extends AlarmWeekdays
    with TableInfo<$AlarmWeekdaysTable, AlarmWeekday> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlarmWeekdaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _alarmIdMeta =
      const VerificationMeta('alarmId');
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
      'alarm_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weekdayMeta =
      const VerificationMeta('weekday');
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
      'weekday', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [alarmId, weekday];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alarm_weekdays';
  @override
  VerificationContext validateIntegrity(Insertable<AlarmWeekday> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('alarm_id')) {
      context.handle(_alarmIdMeta,
          alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta));
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(_weekdayMeta,
          weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta));
    } else if (isInserting) {
      context.missing(_weekdayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {alarmId, weekday};
  @override
  AlarmWeekday map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlarmWeekday(
      alarmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alarm_id'])!,
      weekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}weekday'])!,
    );
  }

  @override
  $AlarmWeekdaysTable createAlias(String alias) {
    return $AlarmWeekdaysTable(attachedDatabase, alias);
  }
}

class AlarmWeekday extends DataClass implements Insertable<AlarmWeekday> {
  final String alarmId;
  final int weekday;
  const AlarmWeekday({required this.alarmId, required this.weekday});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['alarm_id'] = Variable<String>(alarmId);
    map['weekday'] = Variable<int>(weekday);
    return map;
  }

  AlarmWeekdaysCompanion toCompanion(bool nullToAbsent) {
    return AlarmWeekdaysCompanion(
      alarmId: Value(alarmId),
      weekday: Value(weekday),
    );
  }

  factory AlarmWeekday.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlarmWeekday(
      alarmId: serializer.fromJson<String>(json['alarmId']),
      weekday: serializer.fromJson<int>(json['weekday']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'alarmId': serializer.toJson<String>(alarmId),
      'weekday': serializer.toJson<int>(weekday),
    };
  }

  AlarmWeekday copyWith({String? alarmId, int? weekday}) => AlarmWeekday(
        alarmId: alarmId ?? this.alarmId,
        weekday: weekday ?? this.weekday,
      );
  AlarmWeekday copyWithCompanion(AlarmWeekdaysCompanion data) {
    return AlarmWeekday(
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlarmWeekday(')
          ..write('alarmId: $alarmId, ')
          ..write('weekday: $weekday')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(alarmId, weekday);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlarmWeekday &&
          other.alarmId == this.alarmId &&
          other.weekday == this.weekday);
}

class AlarmWeekdaysCompanion extends UpdateCompanion<AlarmWeekday> {
  final Value<String> alarmId;
  final Value<int> weekday;
  final Value<int> rowid;
  const AlarmWeekdaysCompanion({
    this.alarmId = const Value.absent(),
    this.weekday = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlarmWeekdaysCompanion.insert({
    required String alarmId,
    required int weekday,
    this.rowid = const Value.absent(),
  })  : alarmId = Value(alarmId),
        weekday = Value(weekday);
  static Insertable<AlarmWeekday> custom({
    Expression<String>? alarmId,
    Expression<int>? weekday,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (alarmId != null) 'alarm_id': alarmId,
      if (weekday != null) 'weekday': weekday,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlarmWeekdaysCompanion copyWith(
      {Value<String>? alarmId, Value<int>? weekday, Value<int>? rowid}) {
    return AlarmWeekdaysCompanion(
      alarmId: alarmId ?? this.alarmId,
      weekday: weekday ?? this.weekday,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlarmWeekdaysCompanion(')
          ..write('alarmId: $alarmId, ')
          ..write('weekday: $weekday, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReincarnationRunsTable extends ReincarnationRuns
    with TableInfo<$ReincarnationRunsTable, ReincarnationRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReincarnationRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _alarmIdMeta =
      const VerificationMeta('alarmId');
  @override
  late final GeneratedColumn<String> alarmId = GeneratedColumn<String>(
      'alarm_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originOccurrenceAtMeta =
      const VerificationMeta('originOccurrenceAt');
  @override
  late final GeneratedColumn<DateTime> originOccurrenceAt =
      GeneratedColumn<DateTime>('origin_occurrence_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _remainingCountMeta =
      const VerificationMeta('remainingCount');
  @override
  late final GeneratedColumn<int> remainingCount = GeneratedColumn<int>(
      'remaining_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nextFireAtMeta =
      const VerificationMeta('nextFireAt');
  @override
  late final GeneratedColumn<DateTime> nextFireAt = GeneratedColumn<DateTime>(
      'next_fire_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, alarmId, originOccurrenceAt, remainingCount, nextFireAt, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reincarnation_runs';
  @override
  VerificationContext validateIntegrity(Insertable<ReincarnationRun> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alarm_id')) {
      context.handle(_alarmIdMeta,
          alarmId.isAcceptableOrUnknown(data['alarm_id']!, _alarmIdMeta));
    } else if (isInserting) {
      context.missing(_alarmIdMeta);
    }
    if (data.containsKey('origin_occurrence_at')) {
      context.handle(
          _originOccurrenceAtMeta,
          originOccurrenceAt.isAcceptableOrUnknown(
              data['origin_occurrence_at']!, _originOccurrenceAtMeta));
    } else if (isInserting) {
      context.missing(_originOccurrenceAtMeta);
    }
    if (data.containsKey('remaining_count')) {
      context.handle(
          _remainingCountMeta,
          remainingCount.isAcceptableOrUnknown(
              data['remaining_count']!, _remainingCountMeta));
    } else if (isInserting) {
      context.missing(_remainingCountMeta);
    }
    if (data.containsKey('next_fire_at')) {
      context.handle(
          _nextFireAtMeta,
          nextFireAt.isAcceptableOrUnknown(
              data['next_fire_at']!, _nextFireAtMeta));
    } else if (isInserting) {
      context.missing(_nextFireAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReincarnationRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReincarnationRun(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      alarmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alarm_id'])!,
      originOccurrenceAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}origin_occurrence_at'])!,
      remainingCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remaining_count'])!,
      nextFireAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_fire_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $ReincarnationRunsTable createAlias(String alias) {
    return $ReincarnationRunsTable(attachedDatabase, alias);
  }
}

class ReincarnationRun extends DataClass
    implements Insertable<ReincarnationRun> {
  final String id;
  final String alarmId;
  final DateTime originOccurrenceAt;
  final int remainingCount;
  final DateTime nextFireAt;
  final int status;
  const ReincarnationRun(
      {required this.id,
      required this.alarmId,
      required this.originOccurrenceAt,
      required this.remainingCount,
      required this.nextFireAt,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['alarm_id'] = Variable<String>(alarmId);
    map['origin_occurrence_at'] = Variable<DateTime>(originOccurrenceAt);
    map['remaining_count'] = Variable<int>(remainingCount);
    map['next_fire_at'] = Variable<DateTime>(nextFireAt);
    map['status'] = Variable<int>(status);
    return map;
  }

  ReincarnationRunsCompanion toCompanion(bool nullToAbsent) {
    return ReincarnationRunsCompanion(
      id: Value(id),
      alarmId: Value(alarmId),
      originOccurrenceAt: Value(originOccurrenceAt),
      remainingCount: Value(remainingCount),
      nextFireAt: Value(nextFireAt),
      status: Value(status),
    );
  }

  factory ReincarnationRun.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReincarnationRun(
      id: serializer.fromJson<String>(json['id']),
      alarmId: serializer.fromJson<String>(json['alarmId']),
      originOccurrenceAt:
          serializer.fromJson<DateTime>(json['originOccurrenceAt']),
      remainingCount: serializer.fromJson<int>(json['remainingCount']),
      nextFireAt: serializer.fromJson<DateTime>(json['nextFireAt']),
      status: serializer.fromJson<int>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'alarmId': serializer.toJson<String>(alarmId),
      'originOccurrenceAt': serializer.toJson<DateTime>(originOccurrenceAt),
      'remainingCount': serializer.toJson<int>(remainingCount),
      'nextFireAt': serializer.toJson<DateTime>(nextFireAt),
      'status': serializer.toJson<int>(status),
    };
  }

  ReincarnationRun copyWith(
          {String? id,
          String? alarmId,
          DateTime? originOccurrenceAt,
          int? remainingCount,
          DateTime? nextFireAt,
          int? status}) =>
      ReincarnationRun(
        id: id ?? this.id,
        alarmId: alarmId ?? this.alarmId,
        originOccurrenceAt: originOccurrenceAt ?? this.originOccurrenceAt,
        remainingCount: remainingCount ?? this.remainingCount,
        nextFireAt: nextFireAt ?? this.nextFireAt,
        status: status ?? this.status,
      );
  ReincarnationRun copyWithCompanion(ReincarnationRunsCompanion data) {
    return ReincarnationRun(
      id: data.id.present ? data.id.value : this.id,
      alarmId: data.alarmId.present ? data.alarmId.value : this.alarmId,
      originOccurrenceAt: data.originOccurrenceAt.present
          ? data.originOccurrenceAt.value
          : this.originOccurrenceAt,
      remainingCount: data.remainingCount.present
          ? data.remainingCount.value
          : this.remainingCount,
      nextFireAt:
          data.nextFireAt.present ? data.nextFireAt.value : this.nextFireAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReincarnationRun(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('originOccurrenceAt: $originOccurrenceAt, ')
          ..write('remainingCount: $remainingCount, ')
          ..write('nextFireAt: $nextFireAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, alarmId, originOccurrenceAt, remainingCount, nextFireAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReincarnationRun &&
          other.id == this.id &&
          other.alarmId == this.alarmId &&
          other.originOccurrenceAt == this.originOccurrenceAt &&
          other.remainingCount == this.remainingCount &&
          other.nextFireAt == this.nextFireAt &&
          other.status == this.status);
}

class ReincarnationRunsCompanion extends UpdateCompanion<ReincarnationRun> {
  final Value<String> id;
  final Value<String> alarmId;
  final Value<DateTime> originOccurrenceAt;
  final Value<int> remainingCount;
  final Value<DateTime> nextFireAt;
  final Value<int> status;
  final Value<int> rowid;
  const ReincarnationRunsCompanion({
    this.id = const Value.absent(),
    this.alarmId = const Value.absent(),
    this.originOccurrenceAt = const Value.absent(),
    this.remainingCount = const Value.absent(),
    this.nextFireAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReincarnationRunsCompanion.insert({
    required String id,
    required String alarmId,
    required DateTime originOccurrenceAt,
    required int remainingCount,
    required DateTime nextFireAt,
    required int status,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        alarmId = Value(alarmId),
        originOccurrenceAt = Value(originOccurrenceAt),
        remainingCount = Value(remainingCount),
        nextFireAt = Value(nextFireAt),
        status = Value(status);
  static Insertable<ReincarnationRun> custom({
    Expression<String>? id,
    Expression<String>? alarmId,
    Expression<DateTime>? originOccurrenceAt,
    Expression<int>? remainingCount,
    Expression<DateTime>? nextFireAt,
    Expression<int>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alarmId != null) 'alarm_id': alarmId,
      if (originOccurrenceAt != null)
        'origin_occurrence_at': originOccurrenceAt,
      if (remainingCount != null) 'remaining_count': remainingCount,
      if (nextFireAt != null) 'next_fire_at': nextFireAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReincarnationRunsCompanion copyWith(
      {Value<String>? id,
      Value<String>? alarmId,
      Value<DateTime>? originOccurrenceAt,
      Value<int>? remainingCount,
      Value<DateTime>? nextFireAt,
      Value<int>? status,
      Value<int>? rowid}) {
    return ReincarnationRunsCompanion(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      originOccurrenceAt: originOccurrenceAt ?? this.originOccurrenceAt,
      remainingCount: remainingCount ?? this.remainingCount,
      nextFireAt: nextFireAt ?? this.nextFireAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (alarmId.present) {
      map['alarm_id'] = Variable<String>(alarmId.value);
    }
    if (originOccurrenceAt.present) {
      map['origin_occurrence_at'] =
          Variable<DateTime>(originOccurrenceAt.value);
    }
    if (remainingCount.present) {
      map['remaining_count'] = Variable<int>(remainingCount.value);
    }
    if (nextFireAt.present) {
      map['next_fire_at'] = Variable<DateTime>(nextFireAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReincarnationRunsCompanion(')
          ..write('id: $id, ')
          ..write('alarmId: $alarmId, ')
          ..write('originOccurrenceAt: $originOccurrenceAt, ')
          ..write('remainingCount: $remainingCount, ')
          ..write('nextFireAt: $nextFireAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StopwatchSessionsTable extends StopwatchSessions
    with TableInfo<$StopwatchSessionsTable, StopwatchSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopwatchSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalTimeMsMeta =
      const VerificationMeta('totalTimeMs');
  @override
  late final GeneratedColumn<int> totalTimeMs = GeneratedColumn<int>(
      'total_time_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, startedAt, endedAt, totalTimeMs, status, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stopwatch_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<StopwatchSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('total_time_ms')) {
      context.handle(
          _totalTimeMsMeta,
          totalTimeMs.isAcceptableOrUnknown(
              data['total_time_ms']!, _totalTimeMsMeta));
    } else if (isInserting) {
      context.missing(_totalTimeMsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StopwatchSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopwatchSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      totalTimeMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_time_ms'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $StopwatchSessionsTable createAlias(String alias) {
    return $StopwatchSessionsTable(attachedDatabase, alias);
  }
}

class StopwatchSession extends DataClass
    implements Insertable<StopwatchSession> {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int totalTimeMs;
  final int status;
  final DateTime createdAt;
  const StopwatchSession(
      {required this.id,
      required this.startedAt,
      this.endedAt,
      required this.totalTimeMs,
      required this.status,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['total_time_ms'] = Variable<int>(totalTimeMs);
    map['status'] = Variable<int>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StopwatchSessionsCompanion toCompanion(bool nullToAbsent) {
    return StopwatchSessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      totalTimeMs: Value(totalTimeMs),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory StopwatchSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopwatchSession(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      totalTimeMs: serializer.fromJson<int>(json['totalTimeMs']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'totalTimeMs': serializer.toJson<int>(totalTimeMs),
      'status': serializer.toJson<int>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StopwatchSession copyWith(
          {String? id,
          DateTime? startedAt,
          Value<DateTime?> endedAt = const Value.absent(),
          int? totalTimeMs,
          int? status,
          DateTime? createdAt}) =>
      StopwatchSession(
        id: id ?? this.id,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        totalTimeMs: totalTimeMs ?? this.totalTimeMs,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
      );
  StopwatchSession copyWithCompanion(StopwatchSessionsCompanion data) {
    return StopwatchSession(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      totalTimeMs:
          data.totalTimeMs.present ? data.totalTimeMs.value : this.totalTimeMs,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopwatchSession(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('totalTimeMs: $totalTimeMs, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startedAt, endedAt, totalTimeMs, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopwatchSession &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.totalTimeMs == this.totalTimeMs &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class StopwatchSessionsCompanion extends UpdateCompanion<StopwatchSession> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> totalTimeMs;
  final Value<int> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StopwatchSessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.totalTimeMs = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StopwatchSessionsCompanion.insert({
    required String id,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required int totalTimeMs,
    required int status,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        startedAt = Value(startedAt),
        totalTimeMs = Value(totalTimeMs),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<StopwatchSession> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? totalTimeMs,
    Expression<int>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (totalTimeMs != null) 'total_time_ms': totalTimeMs,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StopwatchSessionsCompanion copyWith(
      {Value<String>? id,
      Value<DateTime>? startedAt,
      Value<DateTime?>? endedAt,
      Value<int>? totalTimeMs,
      Value<int>? status,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return StopwatchSessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalTimeMs: totalTimeMs ?? this.totalTimeMs,
      status: status ?? this.status,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (totalTimeMs.present) {
      map['total_time_ms'] = Variable<int>(totalTimeMs.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
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
    return (StringBuffer('StopwatchSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('totalTimeMs: $totalTimeMs, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StopwatchLapsTable extends StopwatchLaps
    with TableInfo<$StopwatchLapsTable, StopwatchLap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopwatchLapsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sequenceMeta =
      const VerificationMeta('sequence');
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
      'sequence', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _elapsedAtLapMsMeta =
      const VerificationMeta('elapsedAtLapMs');
  @override
  late final GeneratedColumn<int> elapsedAtLapMs = GeneratedColumn<int>(
      'elapsed_at_lap_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lapDurationMsMeta =
      const VerificationMeta('lapDurationMs');
  @override
  late final GeneratedColumn<int> lapDurationMs = GeneratedColumn<int>(
      'lap_duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, sequence, elapsedAtLapMs, lapDurationMs, recordedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stopwatch_laps';
  @override
  VerificationContext validateIntegrity(Insertable<StopwatchLap> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(_sequenceMeta,
          sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta));
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('elapsed_at_lap_ms')) {
      context.handle(
          _elapsedAtLapMsMeta,
          elapsedAtLapMs.isAcceptableOrUnknown(
              data['elapsed_at_lap_ms']!, _elapsedAtLapMsMeta));
    } else if (isInserting) {
      context.missing(_elapsedAtLapMsMeta);
    }
    if (data.containsKey('lap_duration_ms')) {
      context.handle(
          _lapDurationMsMeta,
          lapDurationMs.isAcceptableOrUnknown(
              data['lap_duration_ms']!, _lapDurationMsMeta));
    } else if (isInserting) {
      context.missing(_lapDurationMsMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StopwatchLap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopwatchLap(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      sequence: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sequence'])!,
      elapsedAtLapMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_at_lap_ms'])!,
      lapDurationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lap_duration_ms'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
    );
  }

  @override
  $StopwatchLapsTable createAlias(String alias) {
    return $StopwatchLapsTable(attachedDatabase, alias);
  }
}

class StopwatchLap extends DataClass implements Insertable<StopwatchLap> {
  final String id;
  final String sessionId;
  final int sequence;
  final int elapsedAtLapMs;
  final int lapDurationMs;
  final DateTime recordedAt;
  const StopwatchLap(
      {required this.id,
      required this.sessionId,
      required this.sequence,
      required this.elapsedAtLapMs,
      required this.lapDurationMs,
      required this.recordedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['sequence'] = Variable<int>(sequence);
    map['elapsed_at_lap_ms'] = Variable<int>(elapsedAtLapMs);
    map['lap_duration_ms'] = Variable<int>(lapDurationMs);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  StopwatchLapsCompanion toCompanion(bool nullToAbsent) {
    return StopwatchLapsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      sequence: Value(sequence),
      elapsedAtLapMs: Value(elapsedAtLapMs),
      lapDurationMs: Value(lapDurationMs),
      recordedAt: Value(recordedAt),
    );
  }

  factory StopwatchLap.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopwatchLap(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      elapsedAtLapMs: serializer.fromJson<int>(json['elapsedAtLapMs']),
      lapDurationMs: serializer.fromJson<int>(json['lapDurationMs']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'sequence': serializer.toJson<int>(sequence),
      'elapsedAtLapMs': serializer.toJson<int>(elapsedAtLapMs),
      'lapDurationMs': serializer.toJson<int>(lapDurationMs),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  StopwatchLap copyWith(
          {String? id,
          String? sessionId,
          int? sequence,
          int? elapsedAtLapMs,
          int? lapDurationMs,
          DateTime? recordedAt}) =>
      StopwatchLap(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        sequence: sequence ?? this.sequence,
        elapsedAtLapMs: elapsedAtLapMs ?? this.elapsedAtLapMs,
        lapDurationMs: lapDurationMs ?? this.lapDurationMs,
        recordedAt: recordedAt ?? this.recordedAt,
      );
  StopwatchLap copyWithCompanion(StopwatchLapsCompanion data) {
    return StopwatchLap(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      elapsedAtLapMs: data.elapsedAtLapMs.present
          ? data.elapsedAtLapMs.value
          : this.elapsedAtLapMs,
      lapDurationMs: data.lapDurationMs.present
          ? data.lapDurationMs.value
          : this.lapDurationMs,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopwatchLap(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('sequence: $sequence, ')
          ..write('elapsedAtLapMs: $elapsedAtLapMs, ')
          ..write('lapDurationMs: $lapDurationMs, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, sessionId, sequence, elapsedAtLapMs, lapDurationMs, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopwatchLap &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.sequence == this.sequence &&
          other.elapsedAtLapMs == this.elapsedAtLapMs &&
          other.lapDurationMs == this.lapDurationMs &&
          other.recordedAt == this.recordedAt);
}

class StopwatchLapsCompanion extends UpdateCompanion<StopwatchLap> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<int> sequence;
  final Value<int> elapsedAtLapMs;
  final Value<int> lapDurationMs;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const StopwatchLapsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.elapsedAtLapMs = const Value.absent(),
    this.lapDurationMs = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StopwatchLapsCompanion.insert({
    required String id,
    required String sessionId,
    required int sequence,
    required int elapsedAtLapMs,
    required int lapDurationMs,
    required DateTime recordedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        sequence = Value(sequence),
        elapsedAtLapMs = Value(elapsedAtLapMs),
        lapDurationMs = Value(lapDurationMs),
        recordedAt = Value(recordedAt);
  static Insertable<StopwatchLap> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<int>? sequence,
    Expression<int>? elapsedAtLapMs,
    Expression<int>? lapDurationMs,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (sequence != null) 'sequence': sequence,
      if (elapsedAtLapMs != null) 'elapsed_at_lap_ms': elapsedAtLapMs,
      if (lapDurationMs != null) 'lap_duration_ms': lapDurationMs,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StopwatchLapsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<int>? sequence,
      Value<int>? elapsedAtLapMs,
      Value<int>? lapDurationMs,
      Value<DateTime>? recordedAt,
      Value<int>? rowid}) {
    return StopwatchLapsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sequence: sequence ?? this.sequence,
      elapsedAtLapMs: elapsedAtLapMs ?? this.elapsedAtLapMs,
      lapDurationMs: lapDurationMs ?? this.lapDurationMs,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (elapsedAtLapMs.present) {
      map['elapsed_at_lap_ms'] = Variable<int>(elapsedAtLapMs.value);
    }
    if (lapDurationMs.present) {
      map['lap_duration_ms'] = Variable<int>(lapDurationMs.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopwatchLapsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('sequence: $sequence, ')
          ..write('elapsedAtLapMs: $elapsedAtLapMs, ')
          ..write('lapDurationMs: $lapDurationMs, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTableTable extends AppSettingsTable
    with TableInfo<$AppSettingsTableTable, AppSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _timePickerStyleMeta =
      const VerificationMeta('timePickerStyle');
  @override
  late final GeneratedColumn<int> timePickerStyle = GeneratedColumn<int>(
      'time_picker_style', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isGroupedViewMeta =
      const VerificationMeta('isGroupedView');
  @override
  late final GeneratedColumn<bool> isGroupedView = GeneratedColumn<bool>(
      'is_grouped_view', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_grouped_view" IN (0, 1))'));
  static const VerificationMeta _defaultRingtoneMeta =
      const VerificationMeta('defaultRingtone');
  @override
  late final GeneratedColumn<String> defaultRingtone = GeneratedColumn<String>(
      'default_ringtone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultVibrationMeta =
      const VerificationMeta('defaultVibration');
  @override
  late final GeneratedColumn<int> defaultVibration = GeneratedColumn<int>(
      'default_vibration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _defaultSnoozeDurationSecondsMeta =
      const VerificationMeta('defaultSnoozeDurationSeconds');
  @override
  late final GeneratedColumn<int> defaultSnoozeDurationSeconds =
      GeneratedColumn<int>(
          'default_snooze_duration_seconds', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        timePickerStyle,
        isGroupedView,
        defaultRingtone,
        defaultVibration,
        defaultSnoozeDurationSeconds
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<AppSettingsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time_picker_style')) {
      context.handle(
          _timePickerStyleMeta,
          timePickerStyle.isAcceptableOrUnknown(
              data['time_picker_style']!, _timePickerStyleMeta));
    } else if (isInserting) {
      context.missing(_timePickerStyleMeta);
    }
    if (data.containsKey('is_grouped_view')) {
      context.handle(
          _isGroupedViewMeta,
          isGroupedView.isAcceptableOrUnknown(
              data['is_grouped_view']!, _isGroupedViewMeta));
    } else if (isInserting) {
      context.missing(_isGroupedViewMeta);
    }
    if (data.containsKey('default_ringtone')) {
      context.handle(
          _defaultRingtoneMeta,
          defaultRingtone.isAcceptableOrUnknown(
              data['default_ringtone']!, _defaultRingtoneMeta));
    } else if (isInserting) {
      context.missing(_defaultRingtoneMeta);
    }
    if (data.containsKey('default_vibration')) {
      context.handle(
          _defaultVibrationMeta,
          defaultVibration.isAcceptableOrUnknown(
              data['default_vibration']!, _defaultVibrationMeta));
    } else if (isInserting) {
      context.missing(_defaultVibrationMeta);
    }
    if (data.containsKey('default_snooze_duration_seconds')) {
      context.handle(
          _defaultSnoozeDurationSecondsMeta,
          defaultSnoozeDurationSeconds.isAcceptableOrUnknown(
              data['default_snooze_duration_seconds']!,
              _defaultSnoozeDurationSecondsMeta));
    } else if (isInserting) {
      context.missing(_defaultSnoozeDurationSecondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      timePickerStyle: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}time_picker_style'])!,
      isGroupedView: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_grouped_view'])!,
      defaultRingtone: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}default_ringtone'])!,
      defaultVibration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}default_vibration'])!,
      defaultSnoozeDurationSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}default_snooze_duration_seconds'])!,
    );
  }

  @override
  $AppSettingsTableTable createAlias(String alias) {
    return $AppSettingsTableTable(attachedDatabase, alias);
  }
}

class AppSettingsTableData extends DataClass
    implements Insertable<AppSettingsTableData> {
  final int id;
  final int timePickerStyle;
  final bool isGroupedView;
  final String defaultRingtone;
  final int defaultVibration;
  final int defaultSnoozeDurationSeconds;
  const AppSettingsTableData(
      {required this.id,
      required this.timePickerStyle,
      required this.isGroupedView,
      required this.defaultRingtone,
      required this.defaultVibration,
      required this.defaultSnoozeDurationSeconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time_picker_style'] = Variable<int>(timePickerStyle);
    map['is_grouped_view'] = Variable<bool>(isGroupedView);
    map['default_ringtone'] = Variable<String>(defaultRingtone);
    map['default_vibration'] = Variable<int>(defaultVibration);
    map['default_snooze_duration_seconds'] =
        Variable<int>(defaultSnoozeDurationSeconds);
    return map;
  }

  AppSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsTableCompanion(
      id: Value(id),
      timePickerStyle: Value(timePickerStyle),
      isGroupedView: Value(isGroupedView),
      defaultRingtone: Value(defaultRingtone),
      defaultVibration: Value(defaultVibration),
      defaultSnoozeDurationSeconds: Value(defaultSnoozeDurationSeconds),
    );
  }

  factory AppSettingsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsTableData(
      id: serializer.fromJson<int>(json['id']),
      timePickerStyle: serializer.fromJson<int>(json['timePickerStyle']),
      isGroupedView: serializer.fromJson<bool>(json['isGroupedView']),
      defaultRingtone: serializer.fromJson<String>(json['defaultRingtone']),
      defaultVibration: serializer.fromJson<int>(json['defaultVibration']),
      defaultSnoozeDurationSeconds:
          serializer.fromJson<int>(json['defaultSnoozeDurationSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timePickerStyle': serializer.toJson<int>(timePickerStyle),
      'isGroupedView': serializer.toJson<bool>(isGroupedView),
      'defaultRingtone': serializer.toJson<String>(defaultRingtone),
      'defaultVibration': serializer.toJson<int>(defaultVibration),
      'defaultSnoozeDurationSeconds':
          serializer.toJson<int>(defaultSnoozeDurationSeconds),
    };
  }

  AppSettingsTableData copyWith(
          {int? id,
          int? timePickerStyle,
          bool? isGroupedView,
          String? defaultRingtone,
          int? defaultVibration,
          int? defaultSnoozeDurationSeconds}) =>
      AppSettingsTableData(
        id: id ?? this.id,
        timePickerStyle: timePickerStyle ?? this.timePickerStyle,
        isGroupedView: isGroupedView ?? this.isGroupedView,
        defaultRingtone: defaultRingtone ?? this.defaultRingtone,
        defaultVibration: defaultVibration ?? this.defaultVibration,
        defaultSnoozeDurationSeconds:
            defaultSnoozeDurationSeconds ?? this.defaultSnoozeDurationSeconds,
      );
  AppSettingsTableData copyWithCompanion(AppSettingsTableCompanion data) {
    return AppSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      timePickerStyle: data.timePickerStyle.present
          ? data.timePickerStyle.value
          : this.timePickerStyle,
      isGroupedView: data.isGroupedView.present
          ? data.isGroupedView.value
          : this.isGroupedView,
      defaultRingtone: data.defaultRingtone.present
          ? data.defaultRingtone.value
          : this.defaultRingtone,
      defaultVibration: data.defaultVibration.present
          ? data.defaultVibration.value
          : this.defaultVibration,
      defaultSnoozeDurationSeconds: data.defaultSnoozeDurationSeconds.present
          ? data.defaultSnoozeDurationSeconds.value
          : this.defaultSnoozeDurationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableData(')
          ..write('id: $id, ')
          ..write('timePickerStyle: $timePickerStyle, ')
          ..write('isGroupedView: $isGroupedView, ')
          ..write('defaultRingtone: $defaultRingtone, ')
          ..write('defaultVibration: $defaultVibration, ')
          ..write('defaultSnoozeDurationSeconds: $defaultSnoozeDurationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timePickerStyle, isGroupedView,
      defaultRingtone, defaultVibration, defaultSnoozeDurationSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsTableData &&
          other.id == this.id &&
          other.timePickerStyle == this.timePickerStyle &&
          other.isGroupedView == this.isGroupedView &&
          other.defaultRingtone == this.defaultRingtone &&
          other.defaultVibration == this.defaultVibration &&
          other.defaultSnoozeDurationSeconds ==
              this.defaultSnoozeDurationSeconds);
}

class AppSettingsTableCompanion extends UpdateCompanion<AppSettingsTableData> {
  final Value<int> id;
  final Value<int> timePickerStyle;
  final Value<bool> isGroupedView;
  final Value<String> defaultRingtone;
  final Value<int> defaultVibration;
  final Value<int> defaultSnoozeDurationSeconds;
  const AppSettingsTableCompanion({
    this.id = const Value.absent(),
    this.timePickerStyle = const Value.absent(),
    this.isGroupedView = const Value.absent(),
    this.defaultRingtone = const Value.absent(),
    this.defaultVibration = const Value.absent(),
    this.defaultSnoozeDurationSeconds = const Value.absent(),
  });
  AppSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required int timePickerStyle,
    required bool isGroupedView,
    required String defaultRingtone,
    required int defaultVibration,
    required int defaultSnoozeDurationSeconds,
  })  : timePickerStyle = Value(timePickerStyle),
        isGroupedView = Value(isGroupedView),
        defaultRingtone = Value(defaultRingtone),
        defaultVibration = Value(defaultVibration),
        defaultSnoozeDurationSeconds = Value(defaultSnoozeDurationSeconds);
  static Insertable<AppSettingsTableData> custom({
    Expression<int>? id,
    Expression<int>? timePickerStyle,
    Expression<bool>? isGroupedView,
    Expression<String>? defaultRingtone,
    Expression<int>? defaultVibration,
    Expression<int>? defaultSnoozeDurationSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timePickerStyle != null) 'time_picker_style': timePickerStyle,
      if (isGroupedView != null) 'is_grouped_view': isGroupedView,
      if (defaultRingtone != null) 'default_ringtone': defaultRingtone,
      if (defaultVibration != null) 'default_vibration': defaultVibration,
      if (defaultSnoozeDurationSeconds != null)
        'default_snooze_duration_seconds': defaultSnoozeDurationSeconds,
    });
  }

  AppSettingsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? timePickerStyle,
      Value<bool>? isGroupedView,
      Value<String>? defaultRingtone,
      Value<int>? defaultVibration,
      Value<int>? defaultSnoozeDurationSeconds}) {
    return AppSettingsTableCompanion(
      id: id ?? this.id,
      timePickerStyle: timePickerStyle ?? this.timePickerStyle,
      isGroupedView: isGroupedView ?? this.isGroupedView,
      defaultRingtone: defaultRingtone ?? this.defaultRingtone,
      defaultVibration: defaultVibration ?? this.defaultVibration,
      defaultSnoozeDurationSeconds:
          defaultSnoozeDurationSeconds ?? this.defaultSnoozeDurationSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timePickerStyle.present) {
      map['time_picker_style'] = Variable<int>(timePickerStyle.value);
    }
    if (isGroupedView.present) {
      map['is_grouped_view'] = Variable<bool>(isGroupedView.value);
    }
    if (defaultRingtone.present) {
      map['default_ringtone'] = Variable<String>(defaultRingtone.value);
    }
    if (defaultVibration.present) {
      map['default_vibration'] = Variable<int>(defaultVibration.value);
    }
    if (defaultSnoozeDurationSeconds.present) {
      map['default_snooze_duration_seconds'] =
          Variable<int>(defaultSnoozeDurationSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('timePickerStyle: $timePickerStyle, ')
          ..write('isGroupedView: $isGroupedView, ')
          ..write('defaultRingtone: $defaultRingtone, ')
          ..write('defaultVibration: $defaultVibration, ')
          ..write('defaultSnoozeDurationSeconds: $defaultSnoozeDurationSeconds')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $AlarmsTable alarms = $AlarmsTable(this);
  late final $AlarmWeekdaysTable alarmWeekdays = $AlarmWeekdaysTable(this);
  late final $ReincarnationRunsTable reincarnationRuns =
      $ReincarnationRunsTable(this);
  late final $StopwatchSessionsTable stopwatchSessions =
      $StopwatchSessionsTable(this);
  late final $StopwatchLapsTable stopwatchLaps = $StopwatchLapsTable(this);
  late final $AppSettingsTableTable appSettingsTable =
      $AppSettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categories,
        alarms,
        alarmWeekdays,
        reincarnationRuns,
        stopwatchSessions,
        stopwatchLaps,
        appSettingsTable
      ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required String emoji,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> emoji,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            emoji: emoji,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String emoji,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            emoji: emoji,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
    Category,
    PrefetchHooks Function()>;
typedef $$AlarmsTableCreateCompanionBuilder = AlarmsCompanion Function({
  required String id,
  required String title,
  Value<String?> categoryId,
  required int scheduleType,
  required int timeOfDay,
  Value<DateTime?> scheduledDate,
  Value<int?> intervalDays,
  Value<DateTime?> scheduleStartDate,
  Value<DateTime?> scheduleEndDate,
  required bool isEnabled,
  required bool deleteAfterUse,
  required String ringtone,
  required int vibration,
  required int snoozeDurationSeconds,
  required int reincarnationCount,
  required int reincarnationIntervalSeconds,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> nextOccurrenceAt,
  Value<int> rowid,
});
typedef $$AlarmsTableUpdateCompanionBuilder = AlarmsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> categoryId,
  Value<int> scheduleType,
  Value<int> timeOfDay,
  Value<DateTime?> scheduledDate,
  Value<int?> intervalDays,
  Value<DateTime?> scheduleStartDate,
  Value<DateTime?> scheduleEndDate,
  Value<bool> isEnabled,
  Value<bool> deleteAfterUse,
  Value<String> ringtone,
  Value<int> vibration,
  Value<int> snoozeDurationSeconds,
  Value<int> reincarnationCount,
  Value<int> reincarnationIntervalSeconds,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> nextOccurrenceAt,
  Value<int> rowid,
});

class $$AlarmsTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scheduleType => $composableBuilder(
      column: $table.scheduleType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduleStartDate => $composableBuilder(
      column: $table.scheduleStartDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get scheduleEndDate => $composableBuilder(
      column: $table.scheduleEndDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleteAfterUse => $composableBuilder(
      column: $table.deleteAfterUse,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ringtone => $composableBuilder(
      column: $table.ringtone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get vibration => $composableBuilder(
      column: $table.vibration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get snoozeDurationSeconds => $composableBuilder(
      column: $table.snoozeDurationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reincarnationCount => $composableBuilder(
      column: $table.reincarnationCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reincarnationIntervalSeconds => $composableBuilder(
      column: $table.reincarnationIntervalSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextOccurrenceAt => $composableBuilder(
      column: $table.nextOccurrenceAt,
      builder: (column) => ColumnFilters(column));
}

class $$AlarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scheduleType => $composableBuilder(
      column: $table.scheduleType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduleStartDate => $composableBuilder(
      column: $table.scheduleStartDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get scheduleEndDate => $composableBuilder(
      column: $table.scheduleEndDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleteAfterUse => $composableBuilder(
      column: $table.deleteAfterUse,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ringtone => $composableBuilder(
      column: $table.ringtone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get vibration => $composableBuilder(
      column: $table.vibration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get snoozeDurationSeconds => $composableBuilder(
      column: $table.snoozeDurationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reincarnationCount => $composableBuilder(
      column: $table.reincarnationCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reincarnationIntervalSeconds => $composableBuilder(
      column: $table.reincarnationIntervalSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextOccurrenceAt => $composableBuilder(
      column: $table.nextOccurrenceAt,
      builder: (column) => ColumnOrderings(column));
}

class $$AlarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmsTable> {
  $$AlarmsTableAnnotationComposer({
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

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get scheduleType => $composableBuilder(
      column: $table.scheduleType, builder: (column) => column);

  GeneratedColumn<int> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
      column: $table.scheduledDate, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
      column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduleStartDate => $composableBuilder(
      column: $table.scheduleStartDate, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduleEndDate => $composableBuilder(
      column: $table.scheduleEndDate, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<bool> get deleteAfterUse => $composableBuilder(
      column: $table.deleteAfterUse, builder: (column) => column);

  GeneratedColumn<String> get ringtone =>
      $composableBuilder(column: $table.ringtone, builder: (column) => column);

  GeneratedColumn<int> get vibration =>
      $composableBuilder(column: $table.vibration, builder: (column) => column);

  GeneratedColumn<int> get snoozeDurationSeconds => $composableBuilder(
      column: $table.snoozeDurationSeconds, builder: (column) => column);

  GeneratedColumn<int> get reincarnationCount => $composableBuilder(
      column: $table.reincarnationCount, builder: (column) => column);

  GeneratedColumn<int> get reincarnationIntervalSeconds => $composableBuilder(
      column: $table.reincarnationIntervalSeconds, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextOccurrenceAt => $composableBuilder(
      column: $table.nextOccurrenceAt, builder: (column) => column);
}

class $$AlarmsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlarmsTable,
    Alarm,
    $$AlarmsTableFilterComposer,
    $$AlarmsTableOrderingComposer,
    $$AlarmsTableAnnotationComposer,
    $$AlarmsTableCreateCompanionBuilder,
    $$AlarmsTableUpdateCompanionBuilder,
    (Alarm, BaseReferences<_$AppDatabase, $AlarmsTable, Alarm>),
    Alarm,
    PrefetchHooks Function()> {
  $$AlarmsTableTableManager(_$AppDatabase db, $AlarmsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> scheduleType = const Value.absent(),
            Value<int> timeOfDay = const Value.absent(),
            Value<DateTime?> scheduledDate = const Value.absent(),
            Value<int?> intervalDays = const Value.absent(),
            Value<DateTime?> scheduleStartDate = const Value.absent(),
            Value<DateTime?> scheduleEndDate = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<bool> deleteAfterUse = const Value.absent(),
            Value<String> ringtone = const Value.absent(),
            Value<int> vibration = const Value.absent(),
            Value<int> snoozeDurationSeconds = const Value.absent(),
            Value<int> reincarnationCount = const Value.absent(),
            Value<int> reincarnationIntervalSeconds = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> nextOccurrenceAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlarmsCompanion(
            id: id,
            title: title,
            categoryId: categoryId,
            scheduleType: scheduleType,
            timeOfDay: timeOfDay,
            scheduledDate: scheduledDate,
            intervalDays: intervalDays,
            scheduleStartDate: scheduleStartDate,
            scheduleEndDate: scheduleEndDate,
            isEnabled: isEnabled,
            deleteAfterUse: deleteAfterUse,
            ringtone: ringtone,
            vibration: vibration,
            snoozeDurationSeconds: snoozeDurationSeconds,
            reincarnationCount: reincarnationCount,
            reincarnationIntervalSeconds: reincarnationIntervalSeconds,
            createdAt: createdAt,
            updatedAt: updatedAt,
            nextOccurrenceAt: nextOccurrenceAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> categoryId = const Value.absent(),
            required int scheduleType,
            required int timeOfDay,
            Value<DateTime?> scheduledDate = const Value.absent(),
            Value<int?> intervalDays = const Value.absent(),
            Value<DateTime?> scheduleStartDate = const Value.absent(),
            Value<DateTime?> scheduleEndDate = const Value.absent(),
            required bool isEnabled,
            required bool deleteAfterUse,
            required String ringtone,
            required int vibration,
            required int snoozeDurationSeconds,
            required int reincarnationCount,
            required int reincarnationIntervalSeconds,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> nextOccurrenceAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlarmsCompanion.insert(
            id: id,
            title: title,
            categoryId: categoryId,
            scheduleType: scheduleType,
            timeOfDay: timeOfDay,
            scheduledDate: scheduledDate,
            intervalDays: intervalDays,
            scheduleStartDate: scheduleStartDate,
            scheduleEndDate: scheduleEndDate,
            isEnabled: isEnabled,
            deleteAfterUse: deleteAfterUse,
            ringtone: ringtone,
            vibration: vibration,
            snoozeDurationSeconds: snoozeDurationSeconds,
            reincarnationCount: reincarnationCount,
            reincarnationIntervalSeconds: reincarnationIntervalSeconds,
            createdAt: createdAt,
            updatedAt: updatedAt,
            nextOccurrenceAt: nextOccurrenceAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AlarmsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlarmsTable,
    Alarm,
    $$AlarmsTableFilterComposer,
    $$AlarmsTableOrderingComposer,
    $$AlarmsTableAnnotationComposer,
    $$AlarmsTableCreateCompanionBuilder,
    $$AlarmsTableUpdateCompanionBuilder,
    (Alarm, BaseReferences<_$AppDatabase, $AlarmsTable, Alarm>),
    Alarm,
    PrefetchHooks Function()>;
typedef $$AlarmWeekdaysTableCreateCompanionBuilder = AlarmWeekdaysCompanion
    Function({
  required String alarmId,
  required int weekday,
  Value<int> rowid,
});
typedef $$AlarmWeekdaysTableUpdateCompanionBuilder = AlarmWeekdaysCompanion
    Function({
  Value<String> alarmId,
  Value<int> weekday,
  Value<int> rowid,
});

class $$AlarmWeekdaysTableFilterComposer
    extends Composer<_$AppDatabase, $AlarmWeekdaysTable> {
  $$AlarmWeekdaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get alarmId => $composableBuilder(
      column: $table.alarmId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnFilters(column));
}

class $$AlarmWeekdaysTableOrderingComposer
    extends Composer<_$AppDatabase, $AlarmWeekdaysTable> {
  $$AlarmWeekdaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get alarmId => $composableBuilder(
      column: $table.alarmId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get weekday => $composableBuilder(
      column: $table.weekday, builder: (column) => ColumnOrderings(column));
}

class $$AlarmWeekdaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlarmWeekdaysTable> {
  $$AlarmWeekdaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get alarmId =>
      $composableBuilder(column: $table.alarmId, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);
}

class $$AlarmWeekdaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AlarmWeekdaysTable,
    AlarmWeekday,
    $$AlarmWeekdaysTableFilterComposer,
    $$AlarmWeekdaysTableOrderingComposer,
    $$AlarmWeekdaysTableAnnotationComposer,
    $$AlarmWeekdaysTableCreateCompanionBuilder,
    $$AlarmWeekdaysTableUpdateCompanionBuilder,
    (
      AlarmWeekday,
      BaseReferences<_$AppDatabase, $AlarmWeekdaysTable, AlarmWeekday>
    ),
    AlarmWeekday,
    PrefetchHooks Function()> {
  $$AlarmWeekdaysTableTableManager(_$AppDatabase db, $AlarmWeekdaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlarmWeekdaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlarmWeekdaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlarmWeekdaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> alarmId = const Value.absent(),
            Value<int> weekday = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AlarmWeekdaysCompanion(
            alarmId: alarmId,
            weekday: weekday,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String alarmId,
            required int weekday,
            Value<int> rowid = const Value.absent(),
          }) =>
              AlarmWeekdaysCompanion.insert(
            alarmId: alarmId,
            weekday: weekday,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AlarmWeekdaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AlarmWeekdaysTable,
    AlarmWeekday,
    $$AlarmWeekdaysTableFilterComposer,
    $$AlarmWeekdaysTableOrderingComposer,
    $$AlarmWeekdaysTableAnnotationComposer,
    $$AlarmWeekdaysTableCreateCompanionBuilder,
    $$AlarmWeekdaysTableUpdateCompanionBuilder,
    (
      AlarmWeekday,
      BaseReferences<_$AppDatabase, $AlarmWeekdaysTable, AlarmWeekday>
    ),
    AlarmWeekday,
    PrefetchHooks Function()>;
typedef $$ReincarnationRunsTableCreateCompanionBuilder
    = ReincarnationRunsCompanion Function({
  required String id,
  required String alarmId,
  required DateTime originOccurrenceAt,
  required int remainingCount,
  required DateTime nextFireAt,
  required int status,
  Value<int> rowid,
});
typedef $$ReincarnationRunsTableUpdateCompanionBuilder
    = ReincarnationRunsCompanion Function({
  Value<String> id,
  Value<String> alarmId,
  Value<DateTime> originOccurrenceAt,
  Value<int> remainingCount,
  Value<DateTime> nextFireAt,
  Value<int> status,
  Value<int> rowid,
});

class $$ReincarnationRunsTableFilterComposer
    extends Composer<_$AppDatabase, $ReincarnationRunsTable> {
  $$ReincarnationRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alarmId => $composableBuilder(
      column: $table.alarmId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get originOccurrenceAt => $composableBuilder(
      column: $table.originOccurrenceAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remainingCount => $composableBuilder(
      column: $table.remainingCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextFireAt => $composableBuilder(
      column: $table.nextFireAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$ReincarnationRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReincarnationRunsTable> {
  $$ReincarnationRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alarmId => $composableBuilder(
      column: $table.alarmId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get originOccurrenceAt => $composableBuilder(
      column: $table.originOccurrenceAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remainingCount => $composableBuilder(
      column: $table.remainingCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextFireAt => $composableBuilder(
      column: $table.nextFireAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$ReincarnationRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReincarnationRunsTable> {
  $$ReincarnationRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alarmId =>
      $composableBuilder(column: $table.alarmId, builder: (column) => column);

  GeneratedColumn<DateTime> get originOccurrenceAt => $composableBuilder(
      column: $table.originOccurrenceAt, builder: (column) => column);

  GeneratedColumn<int> get remainingCount => $composableBuilder(
      column: $table.remainingCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextFireAt => $composableBuilder(
      column: $table.nextFireAt, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ReincarnationRunsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReincarnationRunsTable,
    ReincarnationRun,
    $$ReincarnationRunsTableFilterComposer,
    $$ReincarnationRunsTableOrderingComposer,
    $$ReincarnationRunsTableAnnotationComposer,
    $$ReincarnationRunsTableCreateCompanionBuilder,
    $$ReincarnationRunsTableUpdateCompanionBuilder,
    (
      ReincarnationRun,
      BaseReferences<_$AppDatabase, $ReincarnationRunsTable, ReincarnationRun>
    ),
    ReincarnationRun,
    PrefetchHooks Function()> {
  $$ReincarnationRunsTableTableManager(
      _$AppDatabase db, $ReincarnationRunsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReincarnationRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReincarnationRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReincarnationRunsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> alarmId = const Value.absent(),
            Value<DateTime> originOccurrenceAt = const Value.absent(),
            Value<int> remainingCount = const Value.absent(),
            Value<DateTime> nextFireAt = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReincarnationRunsCompanion(
            id: id,
            alarmId: alarmId,
            originOccurrenceAt: originOccurrenceAt,
            remainingCount: remainingCount,
            nextFireAt: nextFireAt,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String alarmId,
            required DateTime originOccurrenceAt,
            required int remainingCount,
            required DateTime nextFireAt,
            required int status,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReincarnationRunsCompanion.insert(
            id: id,
            alarmId: alarmId,
            originOccurrenceAt: originOccurrenceAt,
            remainingCount: remainingCount,
            nextFireAt: nextFireAt,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReincarnationRunsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReincarnationRunsTable,
    ReincarnationRun,
    $$ReincarnationRunsTableFilterComposer,
    $$ReincarnationRunsTableOrderingComposer,
    $$ReincarnationRunsTableAnnotationComposer,
    $$ReincarnationRunsTableCreateCompanionBuilder,
    $$ReincarnationRunsTableUpdateCompanionBuilder,
    (
      ReincarnationRun,
      BaseReferences<_$AppDatabase, $ReincarnationRunsTable, ReincarnationRun>
    ),
    ReincarnationRun,
    PrefetchHooks Function()>;
typedef $$StopwatchSessionsTableCreateCompanionBuilder
    = StopwatchSessionsCompanion Function({
  required String id,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  required int totalTimeMs,
  required int status,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$StopwatchSessionsTableUpdateCompanionBuilder
    = StopwatchSessionsCompanion Function({
  Value<String> id,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<int> totalTimeMs,
  Value<int> status,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$StopwatchSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $StopwatchSessionsTable> {
  $$StopwatchSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalTimeMs => $composableBuilder(
      column: $table.totalTimeMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$StopwatchSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StopwatchSessionsTable> {
  $$StopwatchSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalTimeMs => $composableBuilder(
      column: $table.totalTimeMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$StopwatchSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopwatchSessionsTable> {
  $$StopwatchSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get totalTimeMs => $composableBuilder(
      column: $table.totalTimeMs, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StopwatchSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StopwatchSessionsTable,
    StopwatchSession,
    $$StopwatchSessionsTableFilterComposer,
    $$StopwatchSessionsTableOrderingComposer,
    $$StopwatchSessionsTableAnnotationComposer,
    $$StopwatchSessionsTableCreateCompanionBuilder,
    $$StopwatchSessionsTableUpdateCompanionBuilder,
    (
      StopwatchSession,
      BaseReferences<_$AppDatabase, $StopwatchSessionsTable, StopwatchSession>
    ),
    StopwatchSession,
    PrefetchHooks Function()> {
  $$StopwatchSessionsTableTableManager(
      _$AppDatabase db, $StopwatchSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopwatchSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopwatchSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopwatchSessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime?> endedAt = const Value.absent(),
            Value<int> totalTimeMs = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StopwatchSessionsCompanion(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            totalTimeMs: totalTimeMs,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required DateTime startedAt,
            Value<DateTime?> endedAt = const Value.absent(),
            required int totalTimeMs,
            required int status,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StopwatchSessionsCompanion.insert(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            totalTimeMs: totalTimeMs,
            status: status,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StopwatchSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StopwatchSessionsTable,
    StopwatchSession,
    $$StopwatchSessionsTableFilterComposer,
    $$StopwatchSessionsTableOrderingComposer,
    $$StopwatchSessionsTableAnnotationComposer,
    $$StopwatchSessionsTableCreateCompanionBuilder,
    $$StopwatchSessionsTableUpdateCompanionBuilder,
    (
      StopwatchSession,
      BaseReferences<_$AppDatabase, $StopwatchSessionsTable, StopwatchSession>
    ),
    StopwatchSession,
    PrefetchHooks Function()>;
typedef $$StopwatchLapsTableCreateCompanionBuilder = StopwatchLapsCompanion
    Function({
  required String id,
  required String sessionId,
  required int sequence,
  required int elapsedAtLapMs,
  required int lapDurationMs,
  required DateTime recordedAt,
  Value<int> rowid,
});
typedef $$StopwatchLapsTableUpdateCompanionBuilder = StopwatchLapsCompanion
    Function({
  Value<String> id,
  Value<String> sessionId,
  Value<int> sequence,
  Value<int> elapsedAtLapMs,
  Value<int> lapDurationMs,
  Value<DateTime> recordedAt,
  Value<int> rowid,
});

class $$StopwatchLapsTableFilterComposer
    extends Composer<_$AppDatabase, $StopwatchLapsTable> {
  $$StopwatchLapsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedAtLapMs => $composableBuilder(
      column: $table.elapsedAtLapMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapDurationMs => $composableBuilder(
      column: $table.lapDurationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));
}

class $$StopwatchLapsTableOrderingComposer
    extends Composer<_$AppDatabase, $StopwatchLapsTable> {
  $$StopwatchLapsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sequence => $composableBuilder(
      column: $table.sequence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedAtLapMs => $composableBuilder(
      column: $table.elapsedAtLapMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapDurationMs => $composableBuilder(
      column: $table.lapDurationMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));
}

class $$StopwatchLapsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopwatchLapsTable> {
  $$StopwatchLapsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<int> get elapsedAtLapMs => $composableBuilder(
      column: $table.elapsedAtLapMs, builder: (column) => column);

  GeneratedColumn<int> get lapDurationMs => $composableBuilder(
      column: $table.lapDurationMs, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);
}

class $$StopwatchLapsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StopwatchLapsTable,
    StopwatchLap,
    $$StopwatchLapsTableFilterComposer,
    $$StopwatchLapsTableOrderingComposer,
    $$StopwatchLapsTableAnnotationComposer,
    $$StopwatchLapsTableCreateCompanionBuilder,
    $$StopwatchLapsTableUpdateCompanionBuilder,
    (
      StopwatchLap,
      BaseReferences<_$AppDatabase, $StopwatchLapsTable, StopwatchLap>
    ),
    StopwatchLap,
    PrefetchHooks Function()> {
  $$StopwatchLapsTableTableManager(_$AppDatabase db, $StopwatchLapsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopwatchLapsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopwatchLapsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopwatchLapsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<int> sequence = const Value.absent(),
            Value<int> elapsedAtLapMs = const Value.absent(),
            Value<int> lapDurationMs = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StopwatchLapsCompanion(
            id: id,
            sessionId: sessionId,
            sequence: sequence,
            elapsedAtLapMs: elapsedAtLapMs,
            lapDurationMs: lapDurationMs,
            recordedAt: recordedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required int sequence,
            required int elapsedAtLapMs,
            required int lapDurationMs,
            required DateTime recordedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StopwatchLapsCompanion.insert(
            id: id,
            sessionId: sessionId,
            sequence: sequence,
            elapsedAtLapMs: elapsedAtLapMs,
            lapDurationMs: lapDurationMs,
            recordedAt: recordedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StopwatchLapsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StopwatchLapsTable,
    StopwatchLap,
    $$StopwatchLapsTableFilterComposer,
    $$StopwatchLapsTableOrderingComposer,
    $$StopwatchLapsTableAnnotationComposer,
    $$StopwatchLapsTableCreateCompanionBuilder,
    $$StopwatchLapsTableUpdateCompanionBuilder,
    (
      StopwatchLap,
      BaseReferences<_$AppDatabase, $StopwatchLapsTable, StopwatchLap>
    ),
    StopwatchLap,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableTableCreateCompanionBuilder
    = AppSettingsTableCompanion Function({
  Value<int> id,
  required int timePickerStyle,
  required bool isGroupedView,
  required String defaultRingtone,
  required int defaultVibration,
  required int defaultSnoozeDurationSeconds,
});
typedef $$AppSettingsTableTableUpdateCompanionBuilder
    = AppSettingsTableCompanion Function({
  Value<int> id,
  Value<int> timePickerStyle,
  Value<bool> isGroupedView,
  Value<String> defaultRingtone,
  Value<int> defaultVibration,
  Value<int> defaultSnoozeDurationSeconds,
});

class $$AppSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timePickerStyle => $composableBuilder(
      column: $table.timePickerStyle,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isGroupedView => $composableBuilder(
      column: $table.isGroupedView, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultRingtone => $composableBuilder(
      column: $table.defaultRingtone,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get defaultVibration => $composableBuilder(
      column: $table.defaultVibration,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get defaultSnoozeDurationSeconds => $composableBuilder(
      column: $table.defaultSnoozeDurationSeconds,
      builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timePickerStyle => $composableBuilder(
      column: $table.timePickerStyle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isGroupedView => $composableBuilder(
      column: $table.isGroupedView,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultRingtone => $composableBuilder(
      column: $table.defaultRingtone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get defaultVibration => $composableBuilder(
      column: $table.defaultVibration,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get defaultSnoozeDurationSeconds => $composableBuilder(
      column: $table.defaultSnoozeDurationSeconds,
      builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTableTable> {
  $$AppSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timePickerStyle => $composableBuilder(
      column: $table.timePickerStyle, builder: (column) => column);

  GeneratedColumn<bool> get isGroupedView => $composableBuilder(
      column: $table.isGroupedView, builder: (column) => column);

  GeneratedColumn<String> get defaultRingtone => $composableBuilder(
      column: $table.defaultRingtone, builder: (column) => column);

  GeneratedColumn<int> get defaultVibration => $composableBuilder(
      column: $table.defaultVibration, builder: (column) => column);

  GeneratedColumn<int> get defaultSnoozeDurationSeconds => $composableBuilder(
      column: $table.defaultSnoozeDurationSeconds, builder: (column) => column);
}

class $$AppSettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingsTableData,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingsTableData,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable,
          AppSettingsTableData>
    ),
    AppSettingsTableData,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableTableManager(
      _$AppDatabase db, $AppSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> timePickerStyle = const Value.absent(),
            Value<bool> isGroupedView = const Value.absent(),
            Value<String> defaultRingtone = const Value.absent(),
            Value<int> defaultVibration = const Value.absent(),
            Value<int> defaultSnoozeDurationSeconds = const Value.absent(),
          }) =>
              AppSettingsTableCompanion(
            id: id,
            timePickerStyle: timePickerStyle,
            isGroupedView: isGroupedView,
            defaultRingtone: defaultRingtone,
            defaultVibration: defaultVibration,
            defaultSnoozeDurationSeconds: defaultSnoozeDurationSeconds,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int timePickerStyle,
            required bool isGroupedView,
            required String defaultRingtone,
            required int defaultVibration,
            required int defaultSnoozeDurationSeconds,
          }) =>
              AppSettingsTableCompanion.insert(
            id: id,
            timePickerStyle: timePickerStyle,
            isGroupedView: isGroupedView,
            defaultRingtone: defaultRingtone,
            defaultVibration: defaultVibration,
            defaultSnoozeDurationSeconds: defaultSnoozeDurationSeconds,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTableTable,
    AppSettingsTableData,
    $$AppSettingsTableTableFilterComposer,
    $$AppSettingsTableTableOrderingComposer,
    $$AppSettingsTableTableAnnotationComposer,
    $$AppSettingsTableTableCreateCompanionBuilder,
    $$AppSettingsTableTableUpdateCompanionBuilder,
    (
      AppSettingsTableData,
      BaseReferences<_$AppDatabase, $AppSettingsTableTable,
          AppSettingsTableData>
    ),
    AppSettingsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$AlarmsTableTableManager get alarms =>
      $$AlarmsTableTableManager(_db, _db.alarms);
  $$AlarmWeekdaysTableTableManager get alarmWeekdays =>
      $$AlarmWeekdaysTableTableManager(_db, _db.alarmWeekdays);
  $$ReincarnationRunsTableTableManager get reincarnationRuns =>
      $$ReincarnationRunsTableTableManager(_db, _db.reincarnationRuns);
  $$StopwatchSessionsTableTableManager get stopwatchSessions =>
      $$StopwatchSessionsTableTableManager(_db, _db.stopwatchSessions);
  $$StopwatchLapsTableTableManager get stopwatchLaps =>
      $$StopwatchLapsTableTableManager(_db, _db.stopwatchLaps);
  $$AppSettingsTableTableTableManager get appSettingsTable =>
      $$AppSettingsTableTableTableManager(_db, _db.appSettingsTable);
}

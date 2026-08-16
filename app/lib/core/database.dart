import 'package:drift/drift.dart';

part 'database.g.dart';

class Herbs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get taste => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get indications => text().nullable()();
  TextColumn get dosage => text().nullable()();
  TextColumn get taboo => text().nullable()();
  TextColumn get raw => text().nullable()();
  TextColumn get original => text().nullable()();
  TextColumn get rongchuan => text().nullable()();
  TextColumn get niZhu => text().nullable()();
}

class Formulas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get keySymptoms => text().withDefault(const Constant(''))();
  TextColumn get representativeMode => text().withDefault(const Constant(''))();
  TextColumn get sourceRef => text().withDefault(const Constant(''))();
}

class TiaoWen extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get number => text().withDefault(const Constant(''))();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get formulaHint => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant(''))();
}

class Cases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().withDefault(const Constant(''))();
  TextColumn get symptoms => text().withDefault(const Constant(''))();
  TextColumn get formula => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant(''))();
}

class Acupoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get meridian => text().withDefault(const Constant(''))();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get indications => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();
}

class RawChunks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get source => text().withDefault(const Constant(''))();
  TextColumn get heading => text().withDefault(const Constant(''))();
  TextColumn get content => text().named('text')();
}

@DriftDatabase(tables: [Herbs, Formulas, TiaoWen, Cases, Acupoints, RawChunks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
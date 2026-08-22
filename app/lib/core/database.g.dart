// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HerbsTable extends Herbs with TableInfo<$HerbsTable, Herb> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HerbsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tasteMeta = const VerificationMeta('taste');
  @override
  late final GeneratedColumn<String> taste = GeneratedColumn<String>(
      'taste', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _indicationsMeta =
      const VerificationMeta('indications');
  @override
  late final GeneratedColumn<String> indications = GeneratedColumn<String>(
      'indications', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
      'dosage', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tabooMeta = const VerificationMeta('taboo');
  @override
  late final GeneratedColumn<String> taboo = GeneratedColumn<String>(
      'taboo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rawMeta = const VerificationMeta('raw');
  @override
  late final GeneratedColumn<String> raw = GeneratedColumn<String>(
      'raw', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originalMeta =
      const VerificationMeta('original');
  @override
  late final GeneratedColumn<String> original = GeneratedColumn<String>(
      'original', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rongchuanMeta =
      const VerificationMeta('rongchuan');
  @override
  late final GeneratedColumn<String> rongchuan = GeneratedColumn<String>(
      'rongchuan', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _niZhuMeta = const VerificationMeta('niZhu');
  @override
  late final GeneratedColumn<String> niZhu = GeneratedColumn<String>(
      'ni_zhu', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        taste,
        category,
        indications,
        dosage,
        taboo,
        raw,
        original,
        rongchuan,
        niZhu
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'herbs';
  @override
  VerificationContext validateIntegrity(Insertable<Herb> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('taste')) {
      context.handle(
          _tasteMeta, taste.isAcceptableOrUnknown(data['taste']!, _tasteMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('indications')) {
      context.handle(
          _indicationsMeta,
          indications.isAcceptableOrUnknown(
              data['indications']!, _indicationsMeta));
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    }
    if (data.containsKey('taboo')) {
      context.handle(
          _tabooMeta, taboo.isAcceptableOrUnknown(data['taboo']!, _tabooMeta));
    }
    if (data.containsKey('raw')) {
      context.handle(
          _rawMeta, raw.isAcceptableOrUnknown(data['raw']!, _rawMeta));
    }
    if (data.containsKey('original')) {
      context.handle(_originalMeta,
          original.isAcceptableOrUnknown(data['original']!, _originalMeta));
    }
    if (data.containsKey('rongchuan')) {
      context.handle(_rongchuanMeta,
          rongchuan.isAcceptableOrUnknown(data['rongchuan']!, _rongchuanMeta));
    }
    if (data.containsKey('ni_zhu')) {
      context.handle(
          _niZhuMeta, niZhu.isAcceptableOrUnknown(data['ni_zhu']!, _niZhuMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Herb map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Herb(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      taste: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}taste']),
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      indications: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}indications']),
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage']),
      taboo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}taboo']),
      raw: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw']),
      original: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original']),
      rongchuan: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rongchuan']),
      niZhu: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ni_zhu']),
    );
  }

  @override
  $HerbsTable createAlias(String alias) {
    return $HerbsTable(attachedDatabase, alias);
  }
}

class Herb extends DataClass implements Insertable<Herb> {
  final int id;
  final String name;
  final String? taste;
  final String? category;
  final String? indications;
  final String? dosage;
  final String? taboo;
  final String? raw;
  final String? original;
  final String? rongchuan;
  final String? niZhu;
  const Herb(
      {required this.id,
      required this.name,
      this.taste,
      this.category,
      this.indications,
      this.dosage,
      this.taboo,
      this.raw,
      this.original,
      this.rongchuan,
      this.niZhu});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || taste != null) {
      map['taste'] = Variable<String>(taste);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || indications != null) {
      map['indications'] = Variable<String>(indications);
    }
    if (!nullToAbsent || dosage != null) {
      map['dosage'] = Variable<String>(dosage);
    }
    if (!nullToAbsent || taboo != null) {
      map['taboo'] = Variable<String>(taboo);
    }
    if (!nullToAbsent || raw != null) {
      map['raw'] = Variable<String>(raw);
    }
    if (!nullToAbsent || original != null) {
      map['original'] = Variable<String>(original);
    }
    if (!nullToAbsent || rongchuan != null) {
      map['rongchuan'] = Variable<String>(rongchuan);
    }
    if (!nullToAbsent || niZhu != null) {
      map['ni_zhu'] = Variable<String>(niZhu);
    }
    return map;
  }

  HerbsCompanion toCompanion(bool nullToAbsent) {
    return HerbsCompanion(
      id: Value(id),
      name: Value(name),
      taste:
          taste == null && nullToAbsent ? const Value.absent() : Value(taste),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      indications: indications == null && nullToAbsent
          ? const Value.absent()
          : Value(indications),
      dosage:
          dosage == null && nullToAbsent ? const Value.absent() : Value(dosage),
      taboo:
          taboo == null && nullToAbsent ? const Value.absent() : Value(taboo),
      raw: raw == null && nullToAbsent ? const Value.absent() : Value(raw),
      original: original == null && nullToAbsent
          ? const Value.absent()
          : Value(original),
      rongchuan: rongchuan == null && nullToAbsent
          ? const Value.absent()
          : Value(rongchuan),
      niZhu:
          niZhu == null && nullToAbsent ? const Value.absent() : Value(niZhu),
    );
  }

  factory Herb.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Herb(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      taste: serializer.fromJson<String?>(json['taste']),
      category: serializer.fromJson<String?>(json['category']),
      indications: serializer.fromJson<String?>(json['indications']),
      dosage: serializer.fromJson<String?>(json['dosage']),
      taboo: serializer.fromJson<String?>(json['taboo']),
      raw: serializer.fromJson<String?>(json['raw']),
      original: serializer.fromJson<String?>(json['original']),
      rongchuan: serializer.fromJson<String?>(json['rongchuan']),
      niZhu: serializer.fromJson<String?>(json['niZhu']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'taste': serializer.toJson<String?>(taste),
      'category': serializer.toJson<String?>(category),
      'indications': serializer.toJson<String?>(indications),
      'dosage': serializer.toJson<String?>(dosage),
      'taboo': serializer.toJson<String?>(taboo),
      'raw': serializer.toJson<String?>(raw),
      'original': serializer.toJson<String?>(original),
      'rongchuan': serializer.toJson<String?>(rongchuan),
      'niZhu': serializer.toJson<String?>(niZhu),
    };
  }

  Herb copyWith(
          {int? id,
          String? name,
          Value<String?> taste = const Value.absent(),
          Value<String?> category = const Value.absent(),
          Value<String?> indications = const Value.absent(),
          Value<String?> dosage = const Value.absent(),
          Value<String?> taboo = const Value.absent(),
          Value<String?> raw = const Value.absent(),
          Value<String?> original = const Value.absent(),
          Value<String?> rongchuan = const Value.absent(),
          Value<String?> niZhu = const Value.absent()}) =>
      Herb(
        id: id ?? this.id,
        name: name ?? this.name,
        taste: taste.present ? taste.value : this.taste,
        category: category.present ? category.value : this.category,
        indications: indications.present ? indications.value : this.indications,
        dosage: dosage.present ? dosage.value : this.dosage,
        taboo: taboo.present ? taboo.value : this.taboo,
        raw: raw.present ? raw.value : this.raw,
        original: original.present ? original.value : this.original,
        rongchuan: rongchuan.present ? rongchuan.value : this.rongchuan,
        niZhu: niZhu.present ? niZhu.value : this.niZhu,
      );
  Herb copyWithCompanion(HerbsCompanion data) {
    return Herb(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      taste: data.taste.present ? data.taste.value : this.taste,
      category: data.category.present ? data.category.value : this.category,
      indications:
          data.indications.present ? data.indications.value : this.indications,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      taboo: data.taboo.present ? data.taboo.value : this.taboo,
      raw: data.raw.present ? data.raw.value : this.raw,
      original: data.original.present ? data.original.value : this.original,
      rongchuan: data.rongchuan.present ? data.rongchuan.value : this.rongchuan,
      niZhu: data.niZhu.present ? data.niZhu.value : this.niZhu,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Herb(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('taste: $taste, ')
          ..write('category: $category, ')
          ..write('indications: $indications, ')
          ..write('dosage: $dosage, ')
          ..write('taboo: $taboo, ')
          ..write('raw: $raw, ')
          ..write('original: $original, ')
          ..write('rongchuan: $rongchuan, ')
          ..write('niZhu: $niZhu')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, taste, category, indications,
      dosage, taboo, raw, original, rongchuan, niZhu);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Herb &&
          other.id == this.id &&
          other.name == this.name &&
          other.taste == this.taste &&
          other.category == this.category &&
          other.indications == this.indications &&
          other.dosage == this.dosage &&
          other.taboo == this.taboo &&
          other.raw == this.raw &&
          other.original == this.original &&
          other.rongchuan == this.rongchuan &&
          other.niZhu == this.niZhu);
}

class HerbsCompanion extends UpdateCompanion<Herb> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> taste;
  final Value<String?> category;
  final Value<String?> indications;
  final Value<String?> dosage;
  final Value<String?> taboo;
  final Value<String?> raw;
  final Value<String?> original;
  final Value<String?> rongchuan;
  final Value<String?> niZhu;
  const HerbsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.taste = const Value.absent(),
    this.category = const Value.absent(),
    this.indications = const Value.absent(),
    this.dosage = const Value.absent(),
    this.taboo = const Value.absent(),
    this.raw = const Value.absent(),
    this.original = const Value.absent(),
    this.rongchuan = const Value.absent(),
    this.niZhu = const Value.absent(),
  });
  HerbsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.taste = const Value.absent(),
    this.category = const Value.absent(),
    this.indications = const Value.absent(),
    this.dosage = const Value.absent(),
    this.taboo = const Value.absent(),
    this.raw = const Value.absent(),
    this.original = const Value.absent(),
    this.rongchuan = const Value.absent(),
    this.niZhu = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Herb> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? taste,
    Expression<String>? category,
    Expression<String>? indications,
    Expression<String>? dosage,
    Expression<String>? taboo,
    Expression<String>? raw,
    Expression<String>? original,
    Expression<String>? rongchuan,
    Expression<String>? niZhu,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (taste != null) 'taste': taste,
      if (category != null) 'category': category,
      if (indications != null) 'indications': indications,
      if (dosage != null) 'dosage': dosage,
      if (taboo != null) 'taboo': taboo,
      if (raw != null) 'raw': raw,
      if (original != null) 'original': original,
      if (rongchuan != null) 'rongchuan': rongchuan,
      if (niZhu != null) 'ni_zhu': niZhu,
    });
  }

  HerbsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? taste,
      Value<String?>? category,
      Value<String?>? indications,
      Value<String?>? dosage,
      Value<String?>? taboo,
      Value<String?>? raw,
      Value<String?>? original,
      Value<String?>? rongchuan,
      Value<String?>? niZhu}) {
    return HerbsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      taste: taste ?? this.taste,
      category: category ?? this.category,
      indications: indications ?? this.indications,
      dosage: dosage ?? this.dosage,
      taboo: taboo ?? this.taboo,
      raw: raw ?? this.raw,
      original: original ?? this.original,
      rongchuan: rongchuan ?? this.rongchuan,
      niZhu: niZhu ?? this.niZhu,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (taste.present) {
      map['taste'] = Variable<String>(taste.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (indications.present) {
      map['indications'] = Variable<String>(indications.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (taboo.present) {
      map['taboo'] = Variable<String>(taboo.value);
    }
    if (raw.present) {
      map['raw'] = Variable<String>(raw.value);
    }
    if (original.present) {
      map['original'] = Variable<String>(original.value);
    }
    if (rongchuan.present) {
      map['rongchuan'] = Variable<String>(rongchuan.value);
    }
    if (niZhu.present) {
      map['ni_zhu'] = Variable<String>(niZhu.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HerbsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('taste: $taste, ')
          ..write('category: $category, ')
          ..write('indications: $indications, ')
          ..write('dosage: $dosage, ')
          ..write('taboo: $taboo, ')
          ..write('raw: $raw, ')
          ..write('original: $original, ')
          ..write('rongchuan: $rongchuan, ')
          ..write('niZhu: $niZhu')
          ..write(')'))
        .toString();
  }
}

class $FormulasTable extends Formulas with TableInfo<$FormulasTable, Formula> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FormulasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _keySymptomsMeta =
      const VerificationMeta('keySymptoms');
  @override
  late final GeneratedColumn<String> keySymptoms = GeneratedColumn<String>(
      'key_symptoms', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _representativeModeMeta =
      const VerificationMeta('representativeMode');
  @override
  late final GeneratedColumn<String> representativeMode =
      GeneratedColumn<String>('representative_mode', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _sourceRefMeta =
      const VerificationMeta('sourceRef');
  @override
  late final GeneratedColumn<String> sourceRef = GeneratedColumn<String>(
      'source_ref', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, title, keySymptoms, representativeMode, sourceRef];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'formulas';
  @override
  VerificationContext validateIntegrity(Insertable<Formula> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('key_symptoms')) {
      context.handle(
          _keySymptomsMeta,
          keySymptoms.isAcceptableOrUnknown(
              data['key_symptoms']!, _keySymptomsMeta));
    }
    if (data.containsKey('representative_mode')) {
      context.handle(
          _representativeModeMeta,
          representativeMode.isAcceptableOrUnknown(
              data['representative_mode']!, _representativeModeMeta));
    }
    if (data.containsKey('source_ref')) {
      context.handle(_sourceRefMeta,
          sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Formula map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Formula(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      keySymptoms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_symptoms'])!,
      representativeMode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}representative_mode'])!,
      sourceRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_ref'])!,
    );
  }

  @override
  $FormulasTable createAlias(String alias) {
    return $FormulasTable(attachedDatabase, alias);
  }
}

class Formula extends DataClass implements Insertable<Formula> {
  final int id;
  final String? name;
  final String? title;
  final String keySymptoms;
  final String representativeMode;
  final String sourceRef;
  const Formula(
      {required this.id,
      this.name,
      this.title,
      required this.keySymptoms,
      required this.representativeMode,
      required this.sourceRef});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['key_symptoms'] = Variable<String>(keySymptoms);
    map['representative_mode'] = Variable<String>(representativeMode);
    map['source_ref'] = Variable<String>(sourceRef);
    return map;
  }

  FormulasCompanion toCompanion(bool nullToAbsent) {
    return FormulasCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      keySymptoms: Value(keySymptoms),
      representativeMode: Value(representativeMode),
      sourceRef: Value(sourceRef),
    );
  }

  factory Formula.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Formula(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      title: serializer.fromJson<String?>(json['title']),
      keySymptoms: serializer.fromJson<String>(json['keySymptoms']),
      representativeMode:
          serializer.fromJson<String>(json['representativeMode']),
      sourceRef: serializer.fromJson<String>(json['sourceRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String?>(name),
      'title': serializer.toJson<String?>(title),
      'keySymptoms': serializer.toJson<String>(keySymptoms),
      'representativeMode': serializer.toJson<String>(representativeMode),
      'sourceRef': serializer.toJson<String>(sourceRef),
    };
  }

  Formula copyWith(
          {int? id,
          Value<String?> name = const Value.absent(),
          Value<String?> title = const Value.absent(),
          String? keySymptoms,
          String? representativeMode,
          String? sourceRef}) =>
      Formula(
        id: id ?? this.id,
        name: name.present ? name.value : this.name,
        title: title.present ? title.value : this.title,
        keySymptoms: keySymptoms ?? this.keySymptoms,
        representativeMode: representativeMode ?? this.representativeMode,
        sourceRef: sourceRef ?? this.sourceRef,
      );
  Formula copyWithCompanion(FormulasCompanion data) {
    return Formula(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      title: data.title.present ? data.title.value : this.title,
      keySymptoms:
          data.keySymptoms.present ? data.keySymptoms.value : this.keySymptoms,
      representativeMode: data.representativeMode.present
          ? data.representativeMode.value
          : this.representativeMode,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Formula(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('keySymptoms: $keySymptoms, ')
          ..write('representativeMode: $representativeMode, ')
          ..write('sourceRef: $sourceRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, title, keySymptoms, representativeMode, sourceRef);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Formula &&
          other.id == this.id &&
          other.name == this.name &&
          other.title == this.title &&
          other.keySymptoms == this.keySymptoms &&
          other.representativeMode == this.representativeMode &&
          other.sourceRef == this.sourceRef);
}

class FormulasCompanion extends UpdateCompanion<Formula> {
  final Value<int> id;
  final Value<String?> name;
  final Value<String?> title;
  final Value<String> keySymptoms;
  final Value<String> representativeMode;
  final Value<String> sourceRef;
  const FormulasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.title = const Value.absent(),
    this.keySymptoms = const Value.absent(),
    this.representativeMode = const Value.absent(),
    this.sourceRef = const Value.absent(),
  });
  FormulasCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.title = const Value.absent(),
    this.keySymptoms = const Value.absent(),
    this.representativeMode = const Value.absent(),
    this.sourceRef = const Value.absent(),
  });
  static Insertable<Formula> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? title,
    Expression<String>? keySymptoms,
    Expression<String>? representativeMode,
    Expression<String>? sourceRef,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (title != null) 'title': title,
      if (keySymptoms != null) 'key_symptoms': keySymptoms,
      if (representativeMode != null) 'representative_mode': representativeMode,
      if (sourceRef != null) 'source_ref': sourceRef,
    });
  }

  FormulasCompanion copyWith(
      {Value<int>? id,
      Value<String?>? name,
      Value<String?>? title,
      Value<String>? keySymptoms,
      Value<String>? representativeMode,
      Value<String>? sourceRef}) {
    return FormulasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      keySymptoms: keySymptoms ?? this.keySymptoms,
      representativeMode: representativeMode ?? this.representativeMode,
      sourceRef: sourceRef ?? this.sourceRef,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (keySymptoms.present) {
      map['key_symptoms'] = Variable<String>(keySymptoms.value);
    }
    if (representativeMode.present) {
      map['representative_mode'] = Variable<String>(representativeMode.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<String>(sourceRef.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FormulasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('title: $title, ')
          ..write('keySymptoms: $keySymptoms, ')
          ..write('representativeMode: $representativeMode, ')
          ..write('sourceRef: $sourceRef')
          ..write(')'))
        .toString();
  }
}

class $TiaoWenTable extends TiaoWen with TableInfo<$TiaoWenTable, TiaoWenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TiaoWenTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
      'number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _formulaHintMeta =
      const VerificationMeta('formulaHint');
  @override
  late final GeneratedColumn<String> formulaHint = GeneratedColumn<String>(
      'formula_hint', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, number, title, body, formulaHint, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tiao_wen';
  @override
  VerificationContext validateIntegrity(Insertable<TiaoWenData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('formula_hint')) {
      context.handle(
          _formulaHintMeta,
          formulaHint.isAcceptableOrUnknown(
              data['formula_hint']!, _formulaHintMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TiaoWenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TiaoWenData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}number'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      formulaHint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}formula_hint'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $TiaoWenTable createAlias(String alias) {
    return $TiaoWenTable(attachedDatabase, alias);
  }
}

class TiaoWenData extends DataClass implements Insertable<TiaoWenData> {
  final int id;
  final String number;
  final String? title;
  final String body;
  final String formulaHint;
  final String source;
  const TiaoWenData(
      {required this.id,
      required this.number,
      this.title,
      required this.body,
      required this.formulaHint,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['number'] = Variable<String>(number);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['body'] = Variable<String>(body);
    map['formula_hint'] = Variable<String>(formulaHint);
    map['source'] = Variable<String>(source);
    return map;
  }

  TiaoWenCompanion toCompanion(bool nullToAbsent) {
    return TiaoWenCompanion(
      id: Value(id),
      number: Value(number),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      body: Value(body),
      formulaHint: Value(formulaHint),
      source: Value(source),
    );
  }

  factory TiaoWenData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TiaoWenData(
      id: serializer.fromJson<int>(json['id']),
      number: serializer.fromJson<String>(json['number']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      formulaHint: serializer.fromJson<String>(json['formulaHint']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'number': serializer.toJson<String>(number),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String>(body),
      'formulaHint': serializer.toJson<String>(formulaHint),
      'source': serializer.toJson<String>(source),
    };
  }

  TiaoWenData copyWith(
          {int? id,
          String? number,
          Value<String?> title = const Value.absent(),
          String? body,
          String? formulaHint,
          String? source}) =>
      TiaoWenData(
        id: id ?? this.id,
        number: number ?? this.number,
        title: title.present ? title.value : this.title,
        body: body ?? this.body,
        formulaHint: formulaHint ?? this.formulaHint,
        source: source ?? this.source,
      );
  TiaoWenData copyWithCompanion(TiaoWenCompanion data) {
    return TiaoWenData(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      formulaHint:
          data.formulaHint.present ? data.formulaHint.value : this.formulaHint,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TiaoWenData(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('formulaHint: $formulaHint, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, number, title, body, formulaHint, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TiaoWenData &&
          other.id == this.id &&
          other.number == this.number &&
          other.title == this.title &&
          other.body == this.body &&
          other.formulaHint == this.formulaHint &&
          other.source == this.source);
}

class TiaoWenCompanion extends UpdateCompanion<TiaoWenData> {
  final Value<int> id;
  final Value<String> number;
  final Value<String?> title;
  final Value<String> body;
  final Value<String> formulaHint;
  final Value<String> source;
  const TiaoWenCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.formulaHint = const Value.absent(),
    this.source = const Value.absent(),
  });
  TiaoWenCompanion.insert({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.formulaHint = const Value.absent(),
    this.source = const Value.absent(),
  });
  static Insertable<TiaoWenData> custom({
    Expression<int>? id,
    Expression<String>? number,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? formulaHint,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (formulaHint != null) 'formula_hint': formulaHint,
      if (source != null) 'source': source,
    });
  }

  TiaoWenCompanion copyWith(
      {Value<int>? id,
      Value<String>? number,
      Value<String?>? title,
      Value<String>? body,
      Value<String>? formulaHint,
      Value<String>? source}) {
    return TiaoWenCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      body: body ?? this.body,
      formulaHint: formulaHint ?? this.formulaHint,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (formulaHint.present) {
      map['formula_hint'] = Variable<String>(formulaHint.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TiaoWenCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('formulaHint: $formulaHint, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $CasesTable extends Cases with TableInfo<$CasesTable, Case> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _symptomsMeta =
      const VerificationMeta('symptoms');
  @override
  late final GeneratedColumn<String> symptoms = GeneratedColumn<String>(
      'symptoms', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _formulaMeta =
      const VerificationMeta('formula');
  @override
  late final GeneratedColumn<String> formula = GeneratedColumn<String>(
      'formula', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, body, symptoms, formula, category, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cases';
  @override
  VerificationContext validateIntegrity(Insertable<Case> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('symptoms')) {
      context.handle(_symptomsMeta,
          symptoms.isAcceptableOrUnknown(data['symptoms']!, _symptomsMeta));
    }
    if (data.containsKey('formula')) {
      context.handle(_formulaMeta,
          formula.isAcceptableOrUnknown(data['formula']!, _formulaMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Case map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Case(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      symptoms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symptoms'])!,
      formula: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}formula'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $CasesTable createAlias(String alias) {
    return $CasesTable(attachedDatabase, alias);
  }
}

class Case extends DataClass implements Insertable<Case> {
  final int id;
  final String? title;
  final String body;
  final String symptoms;
  final String formula;
  final String category;
  final String source;
  const Case(
      {required this.id,
      this.title,
      required this.body,
      required this.symptoms,
      required this.formula,
      required this.category,
      required this.source});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['body'] = Variable<String>(body);
    map['symptoms'] = Variable<String>(symptoms);
    map['formula'] = Variable<String>(formula);
    map['category'] = Variable<String>(category);
    map['source'] = Variable<String>(source);
    return map;
  }

  CasesCompanion toCompanion(bool nullToAbsent) {
    return CasesCompanion(
      id: Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      body: Value(body),
      symptoms: Value(symptoms),
      formula: Value(formula),
      category: Value(category),
      source: Value(source),
    );
  }

  factory Case.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Case(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      symptoms: serializer.fromJson<String>(json['symptoms']),
      formula: serializer.fromJson<String>(json['formula']),
      category: serializer.fromJson<String>(json['category']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String>(body),
      'symptoms': serializer.toJson<String>(symptoms),
      'formula': serializer.toJson<String>(formula),
      'category': serializer.toJson<String>(category),
      'source': serializer.toJson<String>(source),
    };
  }

  Case copyWith(
          {int? id,
          Value<String?> title = const Value.absent(),
          String? body,
          String? symptoms,
          String? formula,
          String? category,
          String? source}) =>
      Case(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        body: body ?? this.body,
        symptoms: symptoms ?? this.symptoms,
        formula: formula ?? this.formula,
        category: category ?? this.category,
        source: source ?? this.source,
      );
  Case copyWithCompanion(CasesCompanion data) {
    return Case(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      symptoms: data.symptoms.present ? data.symptoms.value : this.symptoms,
      formula: data.formula.present ? data.formula.value : this.formula,
      category: data.category.present ? data.category.value : this.category,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Case(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('symptoms: $symptoms, ')
          ..write('formula: $formula, ')
          ..write('category: $category, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, body, symptoms, formula, category, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Case &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.symptoms == this.symptoms &&
          other.formula == this.formula &&
          other.category == this.category &&
          other.source == this.source);
}

class CasesCompanion extends UpdateCompanion<Case> {
  final Value<int> id;
  final Value<String?> title;
  final Value<String> body;
  final Value<String> symptoms;
  final Value<String> formula;
  final Value<String> category;
  final Value<String> source;
  const CasesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.formula = const Value.absent(),
    this.category = const Value.absent(),
    this.source = const Value.absent(),
  });
  CasesCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.formula = const Value.absent(),
    this.category = const Value.absent(),
    this.source = const Value.absent(),
  });
  static Insertable<Case> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? symptoms,
    Expression<String>? formula,
    Expression<String>? category,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (symptoms != null) 'symptoms': symptoms,
      if (formula != null) 'formula': formula,
      if (category != null) 'category': category,
      if (source != null) 'source': source,
    });
  }

  CasesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? title,
      Value<String>? body,
      Value<String>? symptoms,
      Value<String>? formula,
      Value<String>? category,
      Value<String>? source}) {
    return CasesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      symptoms: symptoms ?? this.symptoms,
      formula: formula ?? this.formula,
      category: category ?? this.category,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (symptoms.present) {
      map['symptoms'] = Variable<String>(symptoms.value);
    }
    if (formula.present) {
      map['formula'] = Variable<String>(formula.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CasesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('symptoms: $symptoms, ')
          ..write('formula: $formula, ')
          ..write('category: $category, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $AcupointsTable extends Acupoints
    with TableInfo<$AcupointsTable, Acupoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AcupointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meridianMeta =
      const VerificationMeta('meridian');
  @override
  late final GeneratedColumn<String> meridian = GeneratedColumn<String>(
      'meridian', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _indicationsMeta =
      const VerificationMeta('indications');
  @override
  late final GeneratedColumn<String> indications = GeneratedColumn<String>(
      'indications', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, meridian, location, indications, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'acupoints';
  @override
  VerificationContext validateIntegrity(Insertable<Acupoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('meridian')) {
      context.handle(_meridianMeta,
          meridian.isAcceptableOrUnknown(data['meridian']!, _meridianMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('indications')) {
      context.handle(
          _indicationsMeta,
          indications.isAcceptableOrUnknown(
              data['indications']!, _indicationsMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Acupoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Acupoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      meridian: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meridian'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location'])!,
      indications: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}indications'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
    );
  }

  @override
  $AcupointsTable createAlias(String alias) {
    return $AcupointsTable(attachedDatabase, alias);
  }
}

class Acupoint extends DataClass implements Insertable<Acupoint> {
  final int id;
  final String name;
  final String meridian;
  final String location;
  final String indications;
  final String body;
  const Acupoint(
      {required this.id,
      required this.name,
      required this.meridian,
      required this.location,
      required this.indications,
      required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['meridian'] = Variable<String>(meridian);
    map['location'] = Variable<String>(location);
    map['indications'] = Variable<String>(indications);
    map['body'] = Variable<String>(body);
    return map;
  }

  AcupointsCompanion toCompanion(bool nullToAbsent) {
    return AcupointsCompanion(
      id: Value(id),
      name: Value(name),
      meridian: Value(meridian),
      location: Value(location),
      indications: Value(indications),
      body: Value(body),
    );
  }

  factory Acupoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Acupoint(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      meridian: serializer.fromJson<String>(json['meridian']),
      location: serializer.fromJson<String>(json['location']),
      indications: serializer.fromJson<String>(json['indications']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'meridian': serializer.toJson<String>(meridian),
      'location': serializer.toJson<String>(location),
      'indications': serializer.toJson<String>(indications),
      'body': serializer.toJson<String>(body),
    };
  }

  Acupoint copyWith(
          {int? id,
          String? name,
          String? meridian,
          String? location,
          String? indications,
          String? body}) =>
      Acupoint(
        id: id ?? this.id,
        name: name ?? this.name,
        meridian: meridian ?? this.meridian,
        location: location ?? this.location,
        indications: indications ?? this.indications,
        body: body ?? this.body,
      );
  Acupoint copyWithCompanion(AcupointsCompanion data) {
    return Acupoint(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      meridian: data.meridian.present ? data.meridian.value : this.meridian,
      location: data.location.present ? data.location.value : this.location,
      indications:
          data.indications.present ? data.indications.value : this.indications,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Acupoint(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('meridian: $meridian, ')
          ..write('location: $location, ')
          ..write('indications: $indications, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, meridian, location, indications, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Acupoint &&
          other.id == this.id &&
          other.name == this.name &&
          other.meridian == this.meridian &&
          other.location == this.location &&
          other.indications == this.indications &&
          other.body == this.body);
}

class AcupointsCompanion extends UpdateCompanion<Acupoint> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> meridian;
  final Value<String> location;
  final Value<String> indications;
  final Value<String> body;
  const AcupointsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.meridian = const Value.absent(),
    this.location = const Value.absent(),
    this.indications = const Value.absent(),
    this.body = const Value.absent(),
  });
  AcupointsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.meridian = const Value.absent(),
    this.location = const Value.absent(),
    this.indications = const Value.absent(),
    this.body = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Acupoint> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? meridian,
    Expression<String>? location,
    Expression<String>? indications,
    Expression<String>? body,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (meridian != null) 'meridian': meridian,
      if (location != null) 'location': location,
      if (indications != null) 'indications': indications,
      if (body != null) 'body': body,
    });
  }

  AcupointsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? meridian,
      Value<String>? location,
      Value<String>? indications,
      Value<String>? body}) {
    return AcupointsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      meridian: meridian ?? this.meridian,
      location: location ?? this.location,
      indications: indications ?? this.indications,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (meridian.present) {
      map['meridian'] = Variable<String>(meridian.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (indications.present) {
      map['indications'] = Variable<String>(indications.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AcupointsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('meridian: $meridian, ')
          ..write('location: $location, ')
          ..write('indications: $indications, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}

class $RawChunksTable extends RawChunks
    with TableInfo<$RawChunksTable, RawChunk> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RawChunksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _headingMeta =
      const VerificationMeta('heading');
  @override
  late final GeneratedColumn<String> heading = GeneratedColumn<String>(
      'heading', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, source, heading, content];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raw_chunks';
  @override
  VerificationContext validateIntegrity(Insertable<RawChunk> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('heading')) {
      context.handle(_headingMeta,
          heading.isAcceptableOrUnknown(data['heading']!, _headingMeta));
    }
    if (data.containsKey('text')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['text']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RawChunk map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RawChunk(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      heading: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}heading'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
    );
  }

  @override
  $RawChunksTable createAlias(String alias) {
    return $RawChunksTable(attachedDatabase, alias);
  }
}

class RawChunk extends DataClass implements Insertable<RawChunk> {
  final int id;
  final String source;
  final String heading;
  final String content;
  const RawChunk(
      {required this.id,
      required this.source,
      required this.heading,
      required this.content});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source'] = Variable<String>(source);
    map['heading'] = Variable<String>(heading);
    map['text'] = Variable<String>(content);
    return map;
  }

  RawChunksCompanion toCompanion(bool nullToAbsent) {
    return RawChunksCompanion(
      id: Value(id),
      source: Value(source),
      heading: Value(heading),
      content: Value(content),
    );
  }

  factory RawChunk.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RawChunk(
      id: serializer.fromJson<int>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      heading: serializer.fromJson<String>(json['heading']),
      content: serializer.fromJson<String>(json['content']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source': serializer.toJson<String>(source),
      'heading': serializer.toJson<String>(heading),
      'content': serializer.toJson<String>(content),
    };
  }

  RawChunk copyWith(
          {int? id, String? source, String? heading, String? content}) =>
      RawChunk(
        id: id ?? this.id,
        source: source ?? this.source,
        heading: heading ?? this.heading,
        content: content ?? this.content,
      );
  RawChunk copyWithCompanion(RawChunksCompanion data) {
    return RawChunk(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      heading: data.heading.present ? data.heading.value : this.heading,
      content: data.content.present ? data.content.value : this.content,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RawChunk(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('heading: $heading, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, source, heading, content);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawChunk &&
          other.id == this.id &&
          other.source == this.source &&
          other.heading == this.heading &&
          other.content == this.content);
}

class RawChunksCompanion extends UpdateCompanion<RawChunk> {
  final Value<int> id;
  final Value<String> source;
  final Value<String> heading;
  final Value<String> content;
  const RawChunksCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.heading = const Value.absent(),
    this.content = const Value.absent(),
  });
  RawChunksCompanion.insert({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.heading = const Value.absent(),
    required String content,
  }) : content = Value(content);
  static Insertable<RawChunk> custom({
    Expression<int>? id,
    Expression<String>? source,
    Expression<String>? heading,
    Expression<String>? content,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (heading != null) 'heading': heading,
      if (content != null) 'text': content,
    });
  }

  RawChunksCompanion copyWith(
      {Value<int>? id,
      Value<String>? source,
      Value<String>? heading,
      Value<String>? content}) {
    return RawChunksCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      heading: heading ?? this.heading,
      content: content ?? this.content,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (heading.present) {
      map['heading'] = Variable<String>(heading.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RawChunksCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('heading: $heading, ')
          ..write('content: $content')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HerbsTable herbs = $HerbsTable(this);
  late final $FormulasTable formulas = $FormulasTable(this);
  late final $TiaoWenTable tiaoWen = $TiaoWenTable(this);
  late final $CasesTable cases = $CasesTable(this);
  late final $AcupointsTable acupoints = $AcupointsTable(this);
  late final $RawChunksTable rawChunks = $RawChunksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [herbs, formulas, tiaoWen, cases, acupoints, rawChunks];
}

typedef $$HerbsTableCreateCompanionBuilder = HerbsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> taste,
  Value<String?> category,
  Value<String?> indications,
  Value<String?> dosage,
  Value<String?> taboo,
  Value<String?> raw,
  Value<String?> original,
  Value<String?> rongchuan,
  Value<String?> niZhu,
});
typedef $$HerbsTableUpdateCompanionBuilder = HerbsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> taste,
  Value<String?> category,
  Value<String?> indications,
  Value<String?> dosage,
  Value<String?> taboo,
  Value<String?> raw,
  Value<String?> original,
  Value<String?> rongchuan,
  Value<String?> niZhu,
});

class $$HerbsTableFilterComposer extends Composer<_$AppDatabase, $HerbsTable> {
  $$HerbsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taste => $composableBuilder(
      column: $table.taste, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get indications => $composableBuilder(
      column: $table.indications, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taboo => $composableBuilder(
      column: $table.taboo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get raw => $composableBuilder(
      column: $table.raw, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get original => $composableBuilder(
      column: $table.original, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rongchuan => $composableBuilder(
      column: $table.rongchuan, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get niZhu => $composableBuilder(
      column: $table.niZhu, builder: (column) => ColumnFilters(column));
}

class $$HerbsTableOrderingComposer
    extends Composer<_$AppDatabase, $HerbsTable> {
  $$HerbsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taste => $composableBuilder(
      column: $table.taste, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get indications => $composableBuilder(
      column: $table.indications, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dosage => $composableBuilder(
      column: $table.dosage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taboo => $composableBuilder(
      column: $table.taboo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get raw => $composableBuilder(
      column: $table.raw, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get original => $composableBuilder(
      column: $table.original, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rongchuan => $composableBuilder(
      column: $table.rongchuan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get niZhu => $composableBuilder(
      column: $table.niZhu, builder: (column) => ColumnOrderings(column));
}

class $$HerbsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HerbsTable> {
  $$HerbsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get taste =>
      $composableBuilder(column: $table.taste, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get indications => $composableBuilder(
      column: $table.indications, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get taboo =>
      $composableBuilder(column: $table.taboo, builder: (column) => column);

  GeneratedColumn<String> get raw =>
      $composableBuilder(column: $table.raw, builder: (column) => column);

  GeneratedColumn<String> get original =>
      $composableBuilder(column: $table.original, builder: (column) => column);

  GeneratedColumn<String> get rongchuan =>
      $composableBuilder(column: $table.rongchuan, builder: (column) => column);

  GeneratedColumn<String> get niZhu =>
      $composableBuilder(column: $table.niZhu, builder: (column) => column);
}

class $$HerbsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HerbsTable,
    Herb,
    $$HerbsTableFilterComposer,
    $$HerbsTableOrderingComposer,
    $$HerbsTableAnnotationComposer,
    $$HerbsTableCreateCompanionBuilder,
    $$HerbsTableUpdateCompanionBuilder,
    (Herb, BaseReferences<_$AppDatabase, $HerbsTable, Herb>),
    Herb,
    PrefetchHooks Function()> {
  $$HerbsTableTableManager(_$AppDatabase db, $HerbsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HerbsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HerbsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HerbsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> taste = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> indications = const Value.absent(),
            Value<String?> dosage = const Value.absent(),
            Value<String?> taboo = const Value.absent(),
            Value<String?> raw = const Value.absent(),
            Value<String?> original = const Value.absent(),
            Value<String?> rongchuan = const Value.absent(),
            Value<String?> niZhu = const Value.absent(),
          }) =>
              HerbsCompanion(
            id: id,
            name: name,
            taste: taste,
            category: category,
            indications: indications,
            dosage: dosage,
            taboo: taboo,
            raw: raw,
            original: original,
            rongchuan: rongchuan,
            niZhu: niZhu,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> taste = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<String?> indications = const Value.absent(),
            Value<String?> dosage = const Value.absent(),
            Value<String?> taboo = const Value.absent(),
            Value<String?> raw = const Value.absent(),
            Value<String?> original = const Value.absent(),
            Value<String?> rongchuan = const Value.absent(),
            Value<String?> niZhu = const Value.absent(),
          }) =>
              HerbsCompanion.insert(
            id: id,
            name: name,
            taste: taste,
            category: category,
            indications: indications,
            dosage: dosage,
            taboo: taboo,
            raw: raw,
            original: original,
            rongchuan: rongchuan,
            niZhu: niZhu,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HerbsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HerbsTable,
    Herb,
    $$HerbsTableFilterComposer,
    $$HerbsTableOrderingComposer,
    $$HerbsTableAnnotationComposer,
    $$HerbsTableCreateCompanionBuilder,
    $$HerbsTableUpdateCompanionBuilder,
    (Herb, BaseReferences<_$AppDatabase, $HerbsTable, Herb>),
    Herb,
    PrefetchHooks Function()>;
typedef $$FormulasTableCreateCompanionBuilder = FormulasCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<String?> title,
  Value<String> keySymptoms,
  Value<String> representativeMode,
  Value<String> sourceRef,
});
typedef $$FormulasTableUpdateCompanionBuilder = FormulasCompanion Function({
  Value<int> id,
  Value<String?> name,
  Value<String?> title,
  Value<String> keySymptoms,
  Value<String> representativeMode,
  Value<String> sourceRef,
});

class $$FormulasTableFilterComposer
    extends Composer<_$AppDatabase, $FormulasTable> {
  $$FormulasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keySymptoms => $composableBuilder(
      column: $table.keySymptoms, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get representativeMode => $composableBuilder(
      column: $table.representativeMode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceRef => $composableBuilder(
      column: $table.sourceRef, builder: (column) => ColumnFilters(column));
}

class $$FormulasTableOrderingComposer
    extends Composer<_$AppDatabase, $FormulasTable> {
  $$FormulasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keySymptoms => $composableBuilder(
      column: $table.keySymptoms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get representativeMode => $composableBuilder(
      column: $table.representativeMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceRef => $composableBuilder(
      column: $table.sourceRef, builder: (column) => ColumnOrderings(column));
}

class $$FormulasTableAnnotationComposer
    extends Composer<_$AppDatabase, $FormulasTable> {
  $$FormulasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get keySymptoms => $composableBuilder(
      column: $table.keySymptoms, builder: (column) => column);

  GeneratedColumn<String> get representativeMode => $composableBuilder(
      column: $table.representativeMode, builder: (column) => column);

  GeneratedColumn<String> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);
}

class $$FormulasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FormulasTable,
    Formula,
    $$FormulasTableFilterComposer,
    $$FormulasTableOrderingComposer,
    $$FormulasTableAnnotationComposer,
    $$FormulasTableCreateCompanionBuilder,
    $$FormulasTableUpdateCompanionBuilder,
    (Formula, BaseReferences<_$AppDatabase, $FormulasTable, Formula>),
    Formula,
    PrefetchHooks Function()> {
  $$FormulasTableTableManager(_$AppDatabase db, $FormulasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FormulasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FormulasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FormulasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> keySymptoms = const Value.absent(),
            Value<String> representativeMode = const Value.absent(),
            Value<String> sourceRef = const Value.absent(),
          }) =>
              FormulasCompanion(
            id: id,
            name: name,
            title: title,
            keySymptoms: keySymptoms,
            representativeMode: representativeMode,
            sourceRef: sourceRef,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> name = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> keySymptoms = const Value.absent(),
            Value<String> representativeMode = const Value.absent(),
            Value<String> sourceRef = const Value.absent(),
          }) =>
              FormulasCompanion.insert(
            id: id,
            name: name,
            title: title,
            keySymptoms: keySymptoms,
            representativeMode: representativeMode,
            sourceRef: sourceRef,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FormulasTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FormulasTable,
    Formula,
    $$FormulasTableFilterComposer,
    $$FormulasTableOrderingComposer,
    $$FormulasTableAnnotationComposer,
    $$FormulasTableCreateCompanionBuilder,
    $$FormulasTableUpdateCompanionBuilder,
    (Formula, BaseReferences<_$AppDatabase, $FormulasTable, Formula>),
    Formula,
    PrefetchHooks Function()>;
typedef $$TiaoWenTableCreateCompanionBuilder = TiaoWenCompanion Function({
  Value<int> id,
  Value<String> number,
  Value<String?> title,
  Value<String> body,
  Value<String> formulaHint,
  Value<String> source,
});
typedef $$TiaoWenTableUpdateCompanionBuilder = TiaoWenCompanion Function({
  Value<int> id,
  Value<String> number,
  Value<String?> title,
  Value<String> body,
  Value<String> formulaHint,
  Value<String> source,
});

class $$TiaoWenTableFilterComposer
    extends Composer<_$AppDatabase, $TiaoWenTable> {
  $$TiaoWenTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formulaHint => $composableBuilder(
      column: $table.formulaHint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$TiaoWenTableOrderingComposer
    extends Composer<_$AppDatabase, $TiaoWenTable> {
  $$TiaoWenTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formulaHint => $composableBuilder(
      column: $table.formulaHint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$TiaoWenTableAnnotationComposer
    extends Composer<_$AppDatabase, $TiaoWenTable> {
  $$TiaoWenTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get formulaHint => $composableBuilder(
      column: $table.formulaHint, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$TiaoWenTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TiaoWenTable,
    TiaoWenData,
    $$TiaoWenTableFilterComposer,
    $$TiaoWenTableOrderingComposer,
    $$TiaoWenTableAnnotationComposer,
    $$TiaoWenTableCreateCompanionBuilder,
    $$TiaoWenTableUpdateCompanionBuilder,
    (TiaoWenData, BaseReferences<_$AppDatabase, $TiaoWenTable, TiaoWenData>),
    TiaoWenData,
    PrefetchHooks Function()> {
  $$TiaoWenTableTableManager(_$AppDatabase db, $TiaoWenTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TiaoWenTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TiaoWenTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TiaoWenTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> number = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> formulaHint = const Value.absent(),
            Value<String> source = const Value.absent(),
          }) =>
              TiaoWenCompanion(
            id: id,
            number: number,
            title: title,
            body: body,
            formulaHint: formulaHint,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> number = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> formulaHint = const Value.absent(),
            Value<String> source = const Value.absent(),
          }) =>
              TiaoWenCompanion.insert(
            id: id,
            number: number,
            title: title,
            body: body,
            formulaHint: formulaHint,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TiaoWenTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TiaoWenTable,
    TiaoWenData,
    $$TiaoWenTableFilterComposer,
    $$TiaoWenTableOrderingComposer,
    $$TiaoWenTableAnnotationComposer,
    $$TiaoWenTableCreateCompanionBuilder,
    $$TiaoWenTableUpdateCompanionBuilder,
    (TiaoWenData, BaseReferences<_$AppDatabase, $TiaoWenTable, TiaoWenData>),
    TiaoWenData,
    PrefetchHooks Function()>;
typedef $$CasesTableCreateCompanionBuilder = CasesCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<String> body,
  Value<String> symptoms,
  Value<String> formula,
  Value<String> category,
  Value<String> source,
});
typedef $$CasesTableUpdateCompanionBuilder = CasesCompanion Function({
  Value<int> id,
  Value<String?> title,
  Value<String> body,
  Value<String> symptoms,
  Value<String> formula,
  Value<String> category,
  Value<String> source,
});

class $$CasesTableFilterComposer extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symptoms => $composableBuilder(
      column: $table.symptoms, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formula => $composableBuilder(
      column: $table.formula, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$CasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symptoms => $composableBuilder(
      column: $table.symptoms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formula => $composableBuilder(
      column: $table.formula, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$CasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CasesTable> {
  $$CasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get symptoms =>
      $composableBuilder(column: $table.symptoms, builder: (column) => column);

  GeneratedColumn<String> get formula =>
      $composableBuilder(column: $table.formula, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$CasesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CasesTable,
    Case,
    $$CasesTableFilterComposer,
    $$CasesTableOrderingComposer,
    $$CasesTableAnnotationComposer,
    $$CasesTableCreateCompanionBuilder,
    $$CasesTableUpdateCompanionBuilder,
    (Case, BaseReferences<_$AppDatabase, $CasesTable, Case>),
    Case,
    PrefetchHooks Function()> {
  $$CasesTableTableManager(_$AppDatabase db, $CasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> symptoms = const Value.absent(),
            Value<String> formula = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> source = const Value.absent(),
          }) =>
              CasesCompanion(
            id: id,
            title: title,
            body: body,
            symptoms: symptoms,
            formula: formula,
            category: category,
            source: source,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> symptoms = const Value.absent(),
            Value<String> formula = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> source = const Value.absent(),
          }) =>
              CasesCompanion.insert(
            id: id,
            title: title,
            body: body,
            symptoms: symptoms,
            formula: formula,
            category: category,
            source: source,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CasesTable,
    Case,
    $$CasesTableFilterComposer,
    $$CasesTableOrderingComposer,
    $$CasesTableAnnotationComposer,
    $$CasesTableCreateCompanionBuilder,
    $$CasesTableUpdateCompanionBuilder,
    (Case, BaseReferences<_$AppDatabase, $CasesTable, Case>),
    Case,
    PrefetchHooks Function()>;
typedef $$AcupointsTableCreateCompanionBuilder = AcupointsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> meridian,
  Value<String> location,
  Value<String> indications,
  Value<String> body,
});
typedef $$AcupointsTableUpdateCompanionBuilder = AcupointsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> meridian,
  Value<String> location,
  Value<String> indications,
  Value<String> body,
});

class $$AcupointsTableFilterComposer
    extends Composer<_$AppDatabase, $AcupointsTable> {
  $$AcupointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meridian => $composableBuilder(
      column: $table.meridian, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get indications => $composableBuilder(
      column: $table.indications, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));
}

class $$AcupointsTableOrderingComposer
    extends Composer<_$AppDatabase, $AcupointsTable> {
  $$AcupointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meridian => $composableBuilder(
      column: $table.meridian, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get indications => $composableBuilder(
      column: $table.indications, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));
}

class $$AcupointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AcupointsTable> {
  $$AcupointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get meridian =>
      $composableBuilder(column: $table.meridian, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get indications => $composableBuilder(
      column: $table.indications, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$AcupointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AcupointsTable,
    Acupoint,
    $$AcupointsTableFilterComposer,
    $$AcupointsTableOrderingComposer,
    $$AcupointsTableAnnotationComposer,
    $$AcupointsTableCreateCompanionBuilder,
    $$AcupointsTableUpdateCompanionBuilder,
    (Acupoint, BaseReferences<_$AppDatabase, $AcupointsTable, Acupoint>),
    Acupoint,
    PrefetchHooks Function()> {
  $$AcupointsTableTableManager(_$AppDatabase db, $AcupointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AcupointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AcupointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AcupointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> meridian = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<String> indications = const Value.absent(),
            Value<String> body = const Value.absent(),
          }) =>
              AcupointsCompanion(
            id: id,
            name: name,
            meridian: meridian,
            location: location,
            indications: indications,
            body: body,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> meridian = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<String> indications = const Value.absent(),
            Value<String> body = const Value.absent(),
          }) =>
              AcupointsCompanion.insert(
            id: id,
            name: name,
            meridian: meridian,
            location: location,
            indications: indications,
            body: body,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AcupointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AcupointsTable,
    Acupoint,
    $$AcupointsTableFilterComposer,
    $$AcupointsTableOrderingComposer,
    $$AcupointsTableAnnotationComposer,
    $$AcupointsTableCreateCompanionBuilder,
    $$AcupointsTableUpdateCompanionBuilder,
    (Acupoint, BaseReferences<_$AppDatabase, $AcupointsTable, Acupoint>),
    Acupoint,
    PrefetchHooks Function()>;
typedef $$RawChunksTableCreateCompanionBuilder = RawChunksCompanion Function({
  Value<int> id,
  Value<String> source,
  Value<String> heading,
  required String content,
});
typedef $$RawChunksTableUpdateCompanionBuilder = RawChunksCompanion Function({
  Value<int> id,
  Value<String> source,
  Value<String> heading,
  Value<String> content,
});

class $$RawChunksTableFilterComposer
    extends Composer<_$AppDatabase, $RawChunksTable> {
  $$RawChunksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get heading => $composableBuilder(
      column: $table.heading, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));
}

class $$RawChunksTableOrderingComposer
    extends Composer<_$AppDatabase, $RawChunksTable> {
  $$RawChunksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get heading => $composableBuilder(
      column: $table.heading, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));
}

class $$RawChunksTableAnnotationComposer
    extends Composer<_$AppDatabase, $RawChunksTable> {
  $$RawChunksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);
}

class $$RawChunksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RawChunksTable,
    RawChunk,
    $$RawChunksTableFilterComposer,
    $$RawChunksTableOrderingComposer,
    $$RawChunksTableAnnotationComposer,
    $$RawChunksTableCreateCompanionBuilder,
    $$RawChunksTableUpdateCompanionBuilder,
    (RawChunk, BaseReferences<_$AppDatabase, $RawChunksTable, RawChunk>),
    RawChunk,
    PrefetchHooks Function()> {
  $$RawChunksTableTableManager(_$AppDatabase db, $RawChunksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RawChunksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RawChunksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RawChunksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> heading = const Value.absent(),
            Value<String> content = const Value.absent(),
          }) =>
              RawChunksCompanion(
            id: id,
            source: source,
            heading: heading,
            content: content,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> heading = const Value.absent(),
            required String content,
          }) =>
              RawChunksCompanion.insert(
            id: id,
            source: source,
            heading: heading,
            content: content,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RawChunksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RawChunksTable,
    RawChunk,
    $$RawChunksTableFilterComposer,
    $$RawChunksTableOrderingComposer,
    $$RawChunksTableAnnotationComposer,
    $$RawChunksTableCreateCompanionBuilder,
    $$RawChunksTableUpdateCompanionBuilder,
    (RawChunk, BaseReferences<_$AppDatabase, $RawChunksTable, RawChunk>),
    RawChunk,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HerbsTableTableManager get herbs =>
      $$HerbsTableTableManager(_db, _db.herbs);
  $$FormulasTableTableManager get formulas =>
      $$FormulasTableTableManager(_db, _db.formulas);
  $$TiaoWenTableTableManager get tiaoWen =>
      $$TiaoWenTableTableManager(_db, _db.tiaoWen);
  $$CasesTableTableManager get cases =>
      $$CasesTableTableManager(_db, _db.cases);
  $$AcupointsTableTableManager get acupoints =>
      $$AcupointsTableTableManager(_db, _db.acupoints);
  $$RawChunksTableTableManager get rawChunks =>
      $$RawChunksTableTableManager(_db, _db.rawChunks);
}

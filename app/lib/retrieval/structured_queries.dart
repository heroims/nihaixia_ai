import 'package:drift/drift.dart';
import 'package:nihaixia_app/core/database.dart';

/// 结构化查询：herbs / tiao_wen / cases / formulas 的轻量检索入口。
///
/// 不走 FTS5，对整段文本用子串 LIKE（同 [Searcher] 的约定）。
/// 对非空字段直接 `.like()`；可空字段由 drift 生成的 `GeneratedColumn<String>`
/// 保证 `.like()` 可用（NULL 不命中）。`%` 作为 SQL 通配符由 SQLite 解析，
/// drift 不做转义，因此 `'%kw%'` 即为子串匹配。
class StructuredQueries {
  /// 现代药名 → 神农本草经古名（仅 herbs.name 存古名）。
  ///
  /// 仅用于 [findHerbs] 的别名扩充，不影响 canonicalize/检索测试。
  /// 全部目标名已在 tools/out/kb.sqlite3 的 herbs 表确认存在。
  static const Map<String, String> _herbAliases = {
    '桂枝': '牡桂',
    '肉桂': '牡桂',
    '黄芪': '黄耆',
    '柴胡': '茈胡',
    '白芍': '芍药',
    '赤芍': '芍药',
    '川芎': '芎穷',
    '山药': '署豫',
    '麦冬': '麦门冬',
    '石菖蒲': '昌蒲',
    '菖蒲': '昌蒲',
    '菊花': '鞠华',
    '黄柏': '檗木',
    '桃仁': '桃核仁',
    '杏仁': '杏核仁',
    '桑白皮': '桑根白皮',
    '桑寄生': '桑上寄生',
    '酸枣仁': '酸枣',
    '柏子仁': '柏实',
    '枸杞子': '枸杞',
    '女贞子': '女贞实',
    '紫菀': '紫苑',
    '荆芥': '假苏',
    '藁本': '槀本',
    '旋覆花': '旋复花',
    '青蒿': '草蒿',
    '常山': '恒山',
    '天麻': '赤箭',
    '天南星': '虎掌',
    '益母草': '充蔚子',
    '海螵蛸': '乌贼鱼骨',
    '肉苁蓉': '肉松容',
    '陈皮': '橘柚',
    '苍耳子': '枲耳实',
    '覆盆子': '蓬蘽',
    '莲子': '藕实茎',
    '芡实': '鸡头实',
    '淡豆豉': '豆豉',
    '川楝子': '楝实',
    '蔓荆子': '蔓荆实',
    '葶苈子': '葶苈',
    '白茅根': '茅根',
    '茜草': '茜根',
  };

  /// 按条文正文/标题子串查询 tiao_wen。
  ///
  /// 库中有 52 条 body 为空（标题必有），故 title 也参与匹配作为回退。
  static Future<List<TiaoWenData>> findTiaoWen(
    AppDatabase db,
    String kw, {
    int limit = 10,
  }) async {
    final like = '%$kw%';
    return (db.select(db.tiaoWen)
          ..where((t) => t.body.like(like) | t.title.like(like))
          ..limit(limit))
        .get();
  }

  /// 按医案正文/标题子串查询 cases。
  ///
  /// symptoms/formula 列在库中基本为空，详情在 body，故以 body 为主。
  static Future<List<Case>> findCases(
    AppDatabase db,
    String kw, {
    int limit = 10,
  }) async {
    final like = '%$kw%';
    return (db.select(db.cases)
          ..where((c) => c.body.like(like) | c.title.like(like))
          ..limit(limit))
        .get();
  }

  /// 按方名/标题/主证子串查询 formulas。
  static Future<List<Formula>> findFormulas(
    AppDatabase db,
    String kw, {
    int limit = 10,
  }) async {
    final like = '%$kw%';
    return (db.select(db.formulas)
          ..where((f) => f.name.like(like) | f.title.like(like) | f.keySymptoms.like(like))
          ..limit(limit))
        .get();
  }

  /// 按药名查询 herbs。
  ///
  /// 语义：`name LIKE %query%`；若 query 在现代名→古名别名表中命中且与
  /// query 不同，追加 `name LIKE %古名%`（OR 语义）。用户输「桂枝」→命中
  /// 牡桂；输「桂」→ 子串命中 牡桂/菌桂/肉桂 等所有含「桂」的条目。
  static Future<List<Herb>> findHerbs(
    AppDatabase db,
    String name, {
    int limit = 10,
  }) async {
    final alias = _herbAliases[name];
    final patterns = <String>['%$name%'];
    if (alias != null && alias != name) patterns.add('%$alias%');
    return (db.select(db.herbs)
          ..where((h) =>
              patterns.map((p) => h.name.like(p)).reduce((a, b) => a | b))
          ..limit(limit))
        .get();
  }
}
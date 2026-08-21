// app/test/utf8_drain_test.dart
// 端侧生成流式解码回归：中文多字节序列被拆在 token 边界时不得产生
// U+FFFD（用户可见的「�」乱码），坏字节需跳过且不能卡死。
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:llama_cpp_dart/src/llama.dart';

void main() {
  test('完整中文字符串一次性解码', () {
    final b = utf8.encode('桂枝汤用于表虚感冒');
    final (out, consumed) = drainUtf8Incremental(b);
    expect(out, '桂枝汤用于表虚感冒');
    expect(consumed, b.length);
  });

  test('三字节汉字拆在 token 边界：保留尾部等拼接，不产生 U+FFFD', () {
    final full = utf8.encode('中'); // E4 B8 AD
    var buf = <int>[full[0]];
    var (out, consumed) = drainUtf8Incremental(buf); // 首字节等待续字节
    expect(out, '');
    expect(consumed, 0);

    buf.add(full[1]);
    (out, consumed) = drainUtf8Incremental(buf); // 还差一个续字节
    expect(out, '');
    expect(consumed, 0);

    buf.add(full[2]);
    (out, consumed) = drainUtf8Incremental(buf);
    expect(out, '中');
    expect(consumed, 3);
  });

  test('四字节 emoji 三段拆分同样保留待拼', () {
    final full = utf8.encode('𝄞'); // U+1D11E，4 字节
    final buf = <int>[...full.sublist(0, 2)];
    var (out, consumed) = drainUtf8Incremental(buf);
    expect(out, '');
    expect(consumed, 0);
    buf.add(full[2]);
    (out, consumed) = drainUtf8Incremental(buf);
    expect(out, '');
    expect(consumed, 0);
    buf.add(full[3]);
    (out, consumed) = drainUtf8Incremental(buf);
    expect(out, '𝄞');
    expect(consumed, 4);
  });

  test('混合流：ASCII 与拆分汉字交错输出正确', () {
    final zh = utf8.encode('中');
    final buf = <int>[...utf8.encode('l'), ...zh.sublist(0, 2)];
    var (out, consumed) = drainUtf8Incremental(buf);
    expect(out, 'l'); // 汉字前半留在缓冲区
    expect(consumed, 1);

    buf.addAll([...zh.sublist(2), ...utf8.encode('o')]);
    (out, consumed) = drainUtf8Incremental(buf.sublist(consumed));
    expect(out, '中o');
    expect(consumed, 4);
  });

  test('真坏字节跳过不卡死、不出现在输出里', () {
    final buf = <int>[
      0xFF, // 非法首字节
      ...utf8.encode('好'),
      0x80, // 孤立续字节
      ...utf8.encode('了'),
    ];
    final (out, _) = drainUtf8Incremental(buf);
    expect(out, '好了');
    expect(out, isNot(contains('\uFFFD')));
  });

  test('断裂序列自我修复：坏续字节后能继续正常解码', () {
    final e4 = utf8.encode('中')[0];
    final buf = <int>[e4, 0x57 /* 'W' 不是合法续字节 */, ...utf8.encode('医')];
    final (out, _) = drainUtf8Incremental(buf);
    expect(out, 'W医');
    expect(out, isNot(contains('\uFFFD')));
  });

  test('长文本逐 token 喂入与整体解码一致（模糊对照）', () {
    const src = '倪海厦经方：桂枝汤治表虚感冒，需注意心脏病史。𝄞混排emoji';
    final all = utf8.encode(src);
    final buf = <int>[];
    final sb = StringBuffer();
    // 模拟真实流式：每 1-3 字节算一个「token」，尾部随机截断多字节字符。
    var i = 0;
    while (i < all.length) {
      final step = (i % 3) + 1;
      buf.addAll(all.sublist(i, (i + step).clamp(0, all.length)));
      i += step;
      final (out, consumed) = drainUtf8Incremental(buf);
      sb.write(out);
      if (consumed > 0) buf.removeRange(0, consumed);
    }
    final (tail, _) = drainUtf8Incremental(buf);
    sb.write(tail);
    expect(sb.toString(), src);
  });
}

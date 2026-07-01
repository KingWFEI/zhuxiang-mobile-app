import 'package:intl/intl.dart';

class DateTimeUtils {
  const DateTimeUtils._();

  // ── DateTime → 字符串 ──────────────────────────────────────────

  static String formatDate(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  static String formatDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }

  /// 与 [formatLeaseDate] 一致的圆点风格日期，如 `2026.07.01`。
  static String formatDateDot(DateTime value) {
    return '${value.year}.${_two(value.month)}.${_two(value.day)}';
  }

  /// 圆点风格的日期时间，如 `2026.07.01 14:30`。
  static String formatDateTimeDot(DateTime value) {
    return '${formatDateDot(value)} ${_two(value.hour)}:${_two(value.minute)}';
  }

  // ── ISO 8601 / 日期字符串 → 格式化字符串 ───────────────────────

  /// 将常见后端日期时间字符串解析为 `yyyy.MM.dd`。
  ///
  /// 支持 `2026-07-01`、`2026-07-01T00:00`、`2026-07-01T00:00+08:00`、
  /// `2026-07-01 00:00:00` 等变体。解析失败返回 `'--'`。
  static String formatDateFromString(String? value) {
    final dt = _tryParse(value);
    if (dt == null) return '--';
    return formatDateDot(dt);
  }

  /// 将常见后端日期时间字符串解析为 `yyyy.MM.dd HH:mm`。
  ///
  /// 解析失败返回 `'--'`。
  static String formatDateTimeFromString(String? value) {
    final dt = _tryParse(value);
    if (dt == null) return '--';
    return formatDateTimeDot(dt);
  }

  /// 起止日期范围，如 `2026.07.01  -  2027.06.30`。
  ///
  /// 两端均为空时返回 `'--'`。
  static String formatDateRange(String? start, String? end) {
    final s = formatDateFromString(start);
    final e = formatDateFromString(end);
    if (s == '--' && e == '--') return '--';
    return '$s  -  $e';
  }

  // ── 内部 ───────────────────────────────────────────────────────

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// 尝试解析常见后端日期时间字符串格式。
  ///
  /// 处理顺序：
  /// 1. 纯日期 `yyyy-MM-dd`
  /// 2. ISO 8601（`T` 分隔，可能带时区）
  /// 3. 空格分隔 `yyyy-MM-dd HH:mm:ss`
  /// 4. 作为最后手段的 `DateTime.tryParse`
  static DateTime? _tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();

    // 1) 纯日期 yyyy-MM-dd
    if (v.length == 10 && v[4] == '-' && v[7] == '-') {
      final parts = v.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }

    // 2) ISO 8601: yyyy-MM-ddTHH:mm 或 yyyy-MM-ddTHH:mm:ss 或带时区
    final tIndex = v.indexOf('T');
    if (tIndex > 0) {
      final datePart = v.substring(0, tIndex);
      // 去掉时区后缀（+08:00 / Z）
      var timePart = v.substring(tIndex + 1);
      final plus = timePart.indexOf('+');
      final minus = timePart.lastIndexOf('-');
      final tzIndex =
          plus > 0 ? plus : (minus > 0 ? minus : timePart.indexOf('Z'));
      if (tzIndex > 0) timePart = timePart.substring(0, tzIndex);

      final dt = DateTime.tryParse('${datePart}T$timePart');
      if (dt != null) return dt;
    }

    // 3) 空格分隔 yyyy-MM-dd HH:mm:ss
    final dt = DateTime.tryParse(v);
    if (dt != null) return dt;

    return null;
  }
}

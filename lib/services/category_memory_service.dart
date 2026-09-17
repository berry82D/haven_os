// lib/services/category_memory_service.dart
// Condensed + Expandable - Remembers YOUR entries, no hardcoded income names
// Tracks biweekly for Salary/Paycheck per David's note
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryMemoryService {
  static const _key = 'haven_category_memory_v1';

  static Future<Map<String, dynamic>> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null)
      return {
        'useCount': {},
        'incomeCount': {},
        'expenseCount': {},
        'lastDates': {}
      };
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded['useCount'] ??= {};
      decoded['incomeCount'] ??= {};
      decoded['expenseCount'] ??= {};
      decoded['lastDates'] ??= {};
      return decoded;
    } catch (_) {
      return {
        'useCount': {},
        'incomeCount': {},
        'expenseCount': {},
        'lastDates': {}
      };
    }
  }

  static Future<void> _save(Map<String, dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(data));
  }

  static Future<void> record(String category, bool isIncome) async {
    final c = category.trim();
    if (c.isEmpty) return;
    final d = await _load();
    final use = Map<String, int>.from((d['useCount'] as Map)
        .map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
    final inc = Map<String, int>.from((d['incomeCount'] as Map)
        .map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
    final exp = Map<String, int>.from((d['expenseCount'] as Map)
        .map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
    final datesRaw = Map<String, dynamic>.from(d['lastDates'] as Map);
    final dates = datesRaw.map((k, v) => MapEntry(
        k.toString(), List<String>.from((v as List).map((e) => e.toString()))));

    use[c] = (use[c] ?? 0) + 1;
    if (isIncome) {
      inc[c] = (inc[c] ?? 0) + 1;
    } else {
      exp[c] = (exp[c] ?? 0) + 1;
    }
    final list = dates[c] ?? <String>[];
    list.add(DateTime.now().toIso8601String());
    dates[c] = list.length > 10 ? list.sublist(list.length - 10) : list;

    d['useCount'] = use;
    d['incomeCount'] = inc;
    d['expenseCount'] = exp;
    d['lastDates'] = dates;
    await _save(d);
  }

  static Future<bool?> learnedIsIncome(String category) async {
    final d = await _load();
    final useMap = d['useCount'] as Map;
    final use = useMap[category] as num?;
    if ((use ?? 0) < 2) return null;
    final incMap = d['incomeCount'] as Map;
    final expMap = d['expenseCount'] as Map;
    final inc = (incMap[category] as num?) ?? 0;
    final exp = (expMap[category] as num?) ?? 0;
    if (inc > exp) return true;
    if (exp > inc) return false;
    return null;
  }

  static Future<int> useCount(String category) async {
    final d = await _load();
    final useMap = d['useCount'] as Map;
    return (useMap[category] as num?)?.toInt() ?? 0;
  }

  static Future<bool> isBiweeklyPattern(String category) async {
    final d = await _load();
    final datesMap = d['lastDates'] as Map;
    final raw = datesMap[category] as List?;
    if (raw == null || raw.length < 3) return false;
    try {
      final dates = raw.map((s) => DateTime.parse(s.toString())).toList()
        ..sort();
      final gaps = <int>[];
      for (var i = 1; i < dates.length; i++) {
        gaps.add(dates[i].difference(dates[i - 1]).inDays);
      }
      final avg = gaps.reduce((a, b) => a + b) / gaps.length;
      return avg >= 12 && avg <= 16;
    } catch (_) {
      return false;
    }
  }

  static Future<DateTime?> nextBiweeklyDate(String category) async {
    final d = await _load();
    final datesMap = d['lastDates'] as Map;
    final raw = datesMap[category] as List?;
    if (raw == null || raw.isEmpty) return null;
    try {
      final last = DateTime.parse(raw.last.toString());
      return last.add(const Duration(days: 14));
    } catch (_) {
      return null;
    }
  }
}

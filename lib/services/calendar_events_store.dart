import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarEventsStore {
  static const _key = 'calendar_events';

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<Map<String, List<String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, ((v as List).map((e) => e.toString())).toList()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(Map<String, List<String>> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(events));
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddedApp {
  final String name;
  final String package;
  AddedApp({required this.name, required this.package});

  Map<String, dynamic> toJson() => {'n': name, 'p': package};

  static AddedApp fromJson(Map<String, dynamic> m) => AddedApp(
        name: (m['n'] as String?) ?? '',
        package: (m['p'] as String?) ?? '',
      );
}

class QuickContact {
  final String name;
  final String number;
  final String? photoPath;
  QuickContact({required this.name, required this.number, this.photoPath});

  Map<String, dynamic> toJson() => {
        'n': name,
        'number': number,
        if (photoPath != null) 'photo': photoPath,
      };

  static QuickContact fromJson(Map<String, dynamic> m) => QuickContact(
        name: (m['n'] as String?) ?? '',
        number: (m['number'] as String?) ?? '',
        photoPath: m['photo'] as String?,
      );
}

class PillReminder {
  final String id;
  final String name;
  final String time; // HH:mm
  final int colorIndex; // index into _colors
  final List<bool> days; // length 7, Sun..Sat

  PillReminder({
    required this.id,
    required this.name,
    required this.time,
    required this.colorIndex,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time,
        'c': colorIndex,
        'd': days.map((e) => e ? 1 : 0).toList(),
      };

  static PillReminder fromJson(Map<String, dynamic> m) => PillReminder(
        id: (m['id'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        time: (m['time'] as String?) ?? '09:00',
        colorIndex: (m['c'] as int?) ?? 0,
        days: ((m['d'] as List?) ?? List.filled(7, 1))
            .map((e) => e == 1)
            .toList(),
      );
}

class AlarmItem {
  final String id;
  final String label;
  final String time; // HH:mm
  final List<bool> days; // length 7
  final bool enabled;

  AlarmItem({
    required this.id,
    required this.label,
    required this.time,
    required this.days,
    required this.enabled,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'time': time,
        'd': days.map((e) => e ? 1 : 0).toList(),
        'e': enabled ? 1 : 0,
      };

  static AlarmItem fromJson(Map<String, dynamic> m) => AlarmItem(
        id: (m['id'] as String?) ?? '',
        label: (m['label'] as String?) ?? '',
        time: (m['time'] as String?) ?? '07:00',
        days: ((m['d'] as List?) ?? List.filled(7, 0)).map((e) => e == 1).toList(),
        enabled: (m['e'] as int?) == 1,
      );
}

class AppMessage {
  final String id;
  final String sender;
  final String body;
  final int timestamp;
  final bool read;

  AppMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
    required this.read,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        's': sender,
        'b': body,
        't': timestamp,
        'r': read ? 1 : 0,
      };

  static AppMessage fromJson(Map<String, dynamic> m) => AppMessage(
        id: (m['id'] as String?) ?? '',
        sender: (m['s'] as String?) ?? '',
        body: (m['b'] as String?) ?? '',
        timestamp: (m['t'] as int?) ?? 0,
        read: (m['r'] as int?) == 1,
      );
}

class CalendarEventItem {
  final String id;
  final String date; // yyyy-mm-dd
  final String title;
  final String note;

  CalendarEventItem({
    required this.id,
    required this.date,
    required this.title,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'title': title,
        'note': note,
      };

  static CalendarEventItem fromJson(Map<String, dynamic> m) =>
      CalendarEventItem(
        id: (m['id'] as String?) ?? '',
        date: (m['date'] as String?) ?? '',
        title: (m['title'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
      );
}

class HomeItemsStore {
  static const _appsKey = 'home_added_apps';
  static const _quickKey = 'home_quick_contacts';
  static const _pillsKey = 'home_pills';
  static const _alarmsKey = 'home_alarms';
  static const _messagesKey = 'home_messages';
  static const _eventsKey = 'home_events';
  static const _skipPermKey = 'skip_permissions';

  static Future<bool> skipPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skipPermKey) ?? false;
  }

  static Future<void> setSkipPermissions(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipPermKey, v);
  }

  static Future<List<AddedApp>> loadApps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list =
          (jsonDecode(raw) as List).map((e) => AddedApp.fromJson(e)).toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveApps(List<AddedApp> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _appsKey, jsonEncode(apps.map((a) => a.toJson()).toList()));
  }

  static Future<List<QuickContact>> loadQuickContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quickKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => QuickContact.fromJson(e))
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveQuickContacts(List<QuickContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _quickKey, jsonEncode(contacts.map((c) => c.toJson()).toList()));
  }

  static Future<List<PillReminder>> loadPills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pillsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PillReminder.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePills(List<PillReminder> pills) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _pillsKey, jsonEncode(pills.map((p) => p.toJson()).toList()));
  }

  static Future<List<AlarmItem>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alarmsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => AlarmItem.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAlarms(List<AlarmItem> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _alarmsKey, jsonEncode(alarms.map((a) => a.toJson()).toList()));
  }

  static Future<List<AppMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => AppMessage.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMessages(List<AppMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _messagesKey, jsonEncode(messages.map((m) => m.toJson()).toList()));
  }

  static Future<int> unreadMessageCount() async {
    final msgs = await loadMessages();
    return msgs.where((m) => !m.read).length;
  }

  static Future<List<CalendarEventItem>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CalendarEventItem.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveEvents(List<CalendarEventItem> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _eventsKey, jsonEncode(events.map((e) => e.toJson()).toList()));
  }
}

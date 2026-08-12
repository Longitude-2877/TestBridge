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

class HomeItemsStore {
  static const _appsKey = 'home_added_apps';
  static const _quickKey = 'home_quick_contacts';

  static Future<List<AddedApp>> loadApps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => AddedApp.fromJson(e as Map<String, dynamic>))
          .toList();
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
          .map((e) => QuickContact.fromJson(e as Map<String, dynamic>))
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
}
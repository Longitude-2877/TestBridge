import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'phone_services.dart';

/// Tracks which messages the user has seen/read in this launcher.
/// Some devices block apps from writing the read flag to the SMS provider,
/// so we keep our own copy of read ids and combine both when counting.
class MessagesStore {
  static const _readKey = 'sms_read_ids';

  static Future<Set<String>> loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readKey, jsonEncode(ids.toList()));
  }

  /// Messages that are still unread, combining the provider flag with the
  /// locally tracked ids (a message is read if either says read).
  static List<SmsMessage> unreadOf(List<SmsMessage> messages,
      Set<String> locallyReadIds) {
    return messages
        .where((m) => m.incoming && !m.read && !locallyReadIds.contains('${m.id}'))
        .toList();
  }

  /// Number for the home-screen badge.
  static Future<int> unreadCount() async {
    final locallyRead = await loadReadIds();
    final providerUnread = await PhoneServices.getUnreadIds();
    final notReadLocally =
        providerUnread.where((id) => !locallyRead.contains('$id')).length;
    return notReadLocally;
  }
}

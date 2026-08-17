import 'package:flutter/material.dart';
import '../services/home_items_store.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_press.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<AppMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var msgs = await HomeItemsStore.loadMessages();
    if (msgs.isEmpty) {
      // Seed a couple of demo messages so the unread badge is visible.
      msgs = [
        AppMessage(
          id: 'seed1',
          sender: 'Dr. Smith',
          body: 'Your appointment is tomorrow at 10 AM.',
          timestamp: DateTime.now()
              .subtract(const Duration(hours: 2))
              .millisecondsSinceEpoch,
          read: false,
        ),
        AppMessage(
          id: 'seed2',
          sender: 'Daughter',
          body: 'Call me when you are free, love you!',
          timestamp: DateTime.now()
              .subtract(const Duration(minutes: 30))
              .millisecondsSinceEpoch,
          read: false,
        ),
      ];
      await HomeItemsStore.saveMessages(msgs);
    }
    if (mounted) setState(() => _messages = msgs);
  }

  Future<void> _save() async => HomeItemsStore.saveMessages(_messages);

  String _time(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    return '$h:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _newMessage() async {
    final sender = TextEditingController();
    final body = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New message',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(controller: sender, hint: 'Sender name'),
            const SizedBox(height: 12),
            CustomTextField(controller: body, hint: 'Message'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: ContraTheme.blue,
                borderRadius: BorderRadius.circular(20),
                child: LongPressInk(
                  onTap: () {
                    if (sender.text.trim().isEmpty ||
                        body.text.trim().isEmpty) return;
                    _messages.insert(
                      0,
                      AppMessage(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        sender: sender.text.trim(),
                        body: body.text.trim(),
                        timestamp: DateTime.now().millisecondsSinceEpoch,
                        read: false,
                      ),
                    );
                    _save();
                    Navigator.of(context).pop();
                    _load();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Send',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRead(int i) {
    final m = _messages[i];
    _messages[i] = AppMessage(
      id: m.id,
      sender: m.sender,
      body: m.body,
      timestamp: m.timestamp,
      read: !m.read,
    );
    _save();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _messages.where((m) => !m.read).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: ContraTheme.ink,
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(
                          color: ContraTheme.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Material(
                color: ContraTheme.blue,
                shape: const CircleBorder(),
                elevation: 2,
                child: LongPressInk(
                  onTap: _newMessage,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(Icons.add_rounded,
                        color: Colors.white, size: 34),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ContraTheme.muted,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Material(
                        color: ContraTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: m.read
                                      ? ContraTheme.muted
                                      : ContraTheme.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  m.read
                                      ? Icons.mark_as_unread_rounded
                                      : Icons.mark_chat_unread_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            m.sender,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: ContraTheme.ink,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _time(m.timestamp),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: ContraTheme.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      m.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: m.read
                                            ? ContraTheme.muted
                                            : ContraTheme.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: m.read
                                    ? ContraTheme.card
                                    : ContraTheme.red,
                                shape: const CircleBorder(),
                                child: LongPressInk(
                                  onTap: () => _toggleRead(i),
                                  customBorder: const CircleBorder(),
                                  child: SizedBox(
                                    width: 46,
                                    height: 46,
                                    child: Icon(
                                      m.read
                                          ? Icons.check_circle_rounded
                                          : Icons.circle,
                                      color: m.read
                                          ? ContraTheme.muted
                                          : Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

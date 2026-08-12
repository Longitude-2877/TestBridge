import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/messages_store.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/custom_keyboard.dart';
import '../widgets/long_tap.dart';
import 'contacts_screen.dart';

class MessagesScreen extends StatefulWidget {
  final VoidCallback onClose;
  const MessagesScreen({super.key, required this.onClose});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<SmsMessage> _messages = [];
  Map<String, String> _names = {};
  Set<String> _readLocally = {};
  String? _threadAddress;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sms = await Permission.sms.request();
    final contacts = await Permission.contacts.request();
    if (!sms.isGranted || !contacts.isGranted) {
      if (mounted) setState(() => _error = true);
      return;
    }
    final readLocally = await MessagesStore.loadReadIds();
    final messages = await PhoneServices.getMessages();
    Map<String, String> names = {};
    for (final c in await PhoneServices.getContacts()) {
      names[_normalize(c.number)] = c.name;
    }
    if (!mounted) return;
    setState(() {
      _readLocally = readLocally;
      _messages = messages;
      _names = names;
      _loading = false;
    });
  }

  String _normalize(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _displayName(String address) {
    final name = _names[_normalize(address)];
    if (name != null && name.isNotEmpty) return name;
    return address.isEmpty ? 'Unknown' : address;
  }

  bool _isRead(SmsMessage m) =>
      m.read || _readLocally.contains('${m.id}');

  List<SmsMessage> _threadOf(String address) =>
      _messages.where((m) => _normalize(m.address) == _normalize(address)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<String> _conversations() {
    final seen = <String>{};
    final out = <String>[];
    for (final m in _messages) {
      final key = _normalize(m.address);
      if (key.isEmpty) continue;
      if (seen.add(key)) out.add(m.address);
    }
    return out;
  }

  SmsMessage? _lastOf(String address) {
    final t = _threadOf(address);
    return t.isEmpty ? null : t.last;
  }

  int _unreadOf(String address) =>
      _threadOf(address).where((m) => m.incoming && !_isRead(m)).length;

  Future<void> _toggleRead(SmsMessage m) async {
    final read = _isRead(m);
    setState(() {
      if (read) {
        _readLocally.remove('${m.id}');
      } else {
        _readLocally.add('${m.id}');
      }
    });
    await MessagesStore.saveReadIds(_readLocally);
    if (read) {
      await PhoneServices.markUnread(m.id);
    } else {
      await PhoneServices.markRead(m.id);
    }
  }

  Future<void> _openNewMessage() async {
    String number = '';
    String name = '';

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New message',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            _OptionRow(
              icon: Icons.contacts_rounded,
              color: ContraTheme.teal,
              title: 'Choose from contacts',
              subtitle: 'Alex, Grandma and more',
              onTap: () => Navigator.of(context).pop('contact'),
            ),
            const SizedBox(height: 10),
            _OptionRow(
              icon: Icons.dialpad_rounded,
              color: ContraTheme.blue,
              title: 'Type a number',
              subtitle: 'Enter the phone number',
              onTap: () => Navigator.of(context).pop('number'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == 'contact') {
      final contact = await showModalBottomSheet<Contact>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: const BoxDecoration(
              color: ContraTheme.bg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ContactsScreen(
                  onSelected: (c) => Navigator.of(context).pop(c),
                ),
              ),
            ),
          ),
        ),
      );
      if (!mounted || contact == null) return;
      number = contact.number;
      name = contact.name;
    } else {
      final numController = TextEditingController();
      final entered = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: ContraTheme.bg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone number',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ContraTheme.ink,
                ),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: numController,
                hint: 'Number',
                numeric: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: ContraTheme.green,
                  borderRadius: BorderRadius.circular(20),
                  child: LongTap(
                    onActivate: () =>
                        Navigator.of(context).pop(numController.text.trim()),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Next',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 21,
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
      if (!mounted || entered == null || entered.isEmpty) return;
      number = entered;
    }

    if (!mounted) return;
    final textController = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? number : 'To $name',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: textController,
              hint: 'Type your message...',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: ContraTheme.green,
                borderRadius: BorderRadius.circular(20),
                child: LongTap(
                  onActivate: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      _toast('Type a message first');
                      return;
                    }
                    final error = await PhoneServices.sendSms(number, text);
                    if (!mounted) return;
                    if (error != null) {
                      _toast(error);
                      return;
                    }
                    Navigator.of(context).pop(true);
                    _toast('Message sent');
                    _load();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Send message',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 21,
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
    if (sent == true) {
      setState(() => _threadAddress = number);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      duration: const Duration(seconds: 2),
    ));
  }

  String _when(int dateMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(dateMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) {
      var h = d.hour % 12;
      if (h == 0) h = 12;
      return '${h}:${d.minute.toString().padLeft(2, '0')} '
          '${d.hour >= 12 ? 'PM' : 'AM'}';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
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
                    if (_threadAddress != null) ...[
                      Material(
                        color: ContraTheme.card,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: LongTap(
                          onActivate: () =>
                              setState(() => _threadAddress = null),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(Icons.arrow_back_rounded,
                                color: ContraTheme.ink, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        _threadAddress == null
                            ? 'Messages'
                            : _displayName(_threadAddress!),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: ContraTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: ContraTheme.teal,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: const Color(0x22000000),
                child: LongTap(
                  onActivate: _openNewMessage,
                  child: const SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error) {
      return const Center(
        child: Text(
          'Messages and contacts\npermission are needed.\nAllow them in the popups and come back.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ContraTheme.muted,
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_threadAddress != null) return _buildThread();
    final convos = _conversations();
    if (convos.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.\nPress + to send a message.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: ContraTheme.muted,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: convos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final address = convos[i];
        final last = _lastOf(address)!;
        final unread = _unreadOf(address);
        return Material(
          color: ContraTheme.card,
          borderRadius: BorderRadius.circular(18),
          elevation: 1,
          child: LongTap(
            onActivate: () => setState(() => _threadAddress = address),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: ContraTheme.teal,
                    child: Text(
                      _displayName(address).isEmpty
                          ? '?'
                          : _displayName(address)[0].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
                                _displayName(address),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: unread > 0
                                      ? ContraTheme.ink
                                      : ContraTheme.muted,
                                ),
                              ),
                            ),
                            Text(
                              _when(last.date),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ContraTheme.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          last.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: unread > 0
                                ? ContraTheme.ink
                                : ContraTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      constraints: const BoxConstraints(minWidth: 34),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: ContraTheme.red,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: ContraTheme.red.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThread() {
    final msgs = _threadOf(_threadAddress!);
    return Column(
      children: [
        Expanded(
          child: msgs.isEmpty
              ? const Center(
                  child: Text(
                    'No messages with this number yet.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: ContraTheme.muted,
                    ),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[msgs.length - 1 - i];
                    return _MessageBubble(
                      message: m,
                      read: _isRead(m),
                      onToggleRead: () => _toggleRead(m),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: ContraTheme.green,
            borderRadius: BorderRadius.circular(20),
            child: LongTap(
              onActivate: _openReply,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Reply',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 21,
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
    );
  }

  Future<void> _openReply() async {
    final textController = TextEditingController();
    final number = _threadAddress!;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ContraTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply to ${_displayName(number)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ContraTheme.ink,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: textController,
              hint: 'Type your message...',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: ContraTheme.green,
                borderRadius: BorderRadius.circular(20),
                child: LongTap(
                  onActivate: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      _toast('Type a message first');
                      return;
                    }
                    final error = await PhoneServices.sendSms(number, text);
                    if (!mounted) return;
                    if (error != null) {
                      _toast(error);
                      return;
                    }
                    Navigator.of(context).pop(true);
                    _toast('Message sent');
                    _load();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Send message',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 21,
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
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ContraTheme.card,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: LongTap(
        onActivate: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ContraTheme.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ContraTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: ContraTheme.muted, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SmsMessage message;
  final bool read;
  final VoidCallback onToggleRead;

  const _MessageBubble({
    required this.message,
    required this.read,
    required this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    final incoming = message.incoming;
    final row = Row(
      mainAxisAlignment:
          incoming ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (incoming) _ReadButton(read: read, onToggle: onToggleRead),
        if (incoming) const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: incoming ? ContraTheme.card : ContraTheme.teal,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: incoming
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  message.body,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: incoming ? ContraTheme.ink : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.date == 0
                      ? ''
                      : _whenQuick(message.date),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: incoming ? ContraTheme.muted : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!incoming) const SizedBox(width: 8),
        if (!incoming) _ReadButton(read: read, onToggle: onToggleRead),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: row,
    );
  }

  static String _whenQuick(int dateMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(dateMs);
    var h = d.hour % 12;
    if (h == 0) h = 12;
    return '${h}:${d.minute.toString().padLeft(2, '0')} '
        '${d.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _ReadButton extends StatelessWidget {
  final bool read;
  final VoidCallback onToggle;

  const _ReadButton({required this.read, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: read ? ContraTheme.green : ContraTheme.red,
      shape: const CircleBorder(),
      elevation: 2,
      child: LongTap(
        onActivate: onToggle,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            read ? Icons.check_rounded : Icons.mark_email_unread_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

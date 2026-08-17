import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_press.dart';
import 'contacts_screen.dart';

class DialerScreen extends StatefulWidget {
  final VoidCallback onClose;
  const DialerScreen({super.key, required this.onClose});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  String _number = '';
  String? _selectedName;

  static const _keys = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#',
  ];

  void _addDigit(String d) {
    setState(() {
      _selectedName = null;
      _number += d;
    });
  }

  void _removeDigit() => setState(() {
        if (_selectedName != null) {
          _selectedName = null;
          _number = '';
        } else {
          _number = _number.isEmpty ? '' : _number.substring(0, _number.length - 1);
        }
      });

  Future<void> _call() async {
    final target = _selectedName != null ? _number : _number;
    if (target.isEmpty) {
      _toast('Enter a number first');
      return;
    }
    final status = await Permission.phone.request();
    if (status.isGranted) {
      final error = await PhoneServices.placeCall(target);
      if (error != null) _toast(error);
    } else {
      _toast('Phone permission needed to call');
    }
  }

  Future<void> _openContacts() async {
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
    // Requirement 7: show the contact's NAME, not the number.
    if (contact != null) {
      setState(() {
        _selectedName = contact.name;
        _number = contact.number;
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final display = _selectedName ?? (_number.isEmpty ? 'Enter number' : _number);
    return Scaffold(
      backgroundColor: ContraTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: ContraTheme.card,
                  border: Border.all(color: ContraTheme.border, width: 2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        display,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: _selectedName != null
                              ? ContraTheme.blue
                              : ContraTheme.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Call using your SIM',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ContraTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final k in _keys)
                      _KeyButton(
                        main: k,
                        onTap: () => _addDigit(k),
                      ),
                    _ActionButton(
                      icon: Icons.contacts_rounded,
                      color: ContraTheme.yellow,
                      onTap: _openContacts,
                    ),
                    _ActionButton(
                      icon: Icons.call_rounded,
                      color: ContraTheme.green,
                      onTap: _call,
                    ),
                    _ActionButton(
                      icon: Icons.backspace_rounded,
                      color: ContraTheme.red,
                      onTap: _removeDigit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String main;
  final VoidCallback onTap;

  const _KeyButton({required this.main, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ContraTheme.card,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: LongPressInk(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            main,
            style: const TextStyle(
              fontFamily: 'Poppins',
              // Requirement 7: larger numbers.
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: ContraTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      elevation: 2,
      child: LongPressInk(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Icon(icon, size: 36, color: Colors.white),
      ),
    );
  }
}

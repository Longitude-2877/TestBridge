import 'package:flutter/material.dart';
import '../services/home_items_store.dart';
import '../services/phone_services.dart';
import '../theme/contra_theme.dart';
import '../widgets/long_press.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _mode = ActivationMode.value;

  static const _options = [
    ('tap', 'Normal tap', 'Tap once to open'),
    ('double', 'Double tap', 'Tap twice to open'),
    ('long', 'Long press', 'Press and hold ~0.2s to open'),
  ];

  Future<void> _choose(String m) async {
    setState(() => _mode = m);
    ActivationMode.set(m);
    await HomeItemsStore.setActivationMode(m);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Settings',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: ContraTheme.ink,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Open apps and buttons by:',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ContraTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final (value, title, sub) in _options)
            _OptionRow(
              title: title,
              subtitle: sub,
              selected: _mode == value,
              // Plain tap so the mode can always be changed, even if the
              // chosen mode makes other buttons harder to trigger.
              onTap: () => _choose(value),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: ContraTheme.blue,
              borderRadius: BorderRadius.circular(20),
              child: LongPressInk(
                onTap: () => PhoneServices.openSettings(),
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Phone settings',
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
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ContraTheme.card,
          border: Border.all(
            color: selected ? ContraTheme.green : ContraTheme.border,
            width: selected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ContraTheme.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ContraTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: ContraTheme.green, size: 30),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/contra_theme.dart';
import 'long_tap.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final String suffix;
  const CustomTextField({
    super.key,
    required this.controller,
    this.hint = '',
    this.numeric = false,
    this.suffix = '',
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LongTap(
      onActivate: () => _openKeyboard(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ContraTheme.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.controller.text.isEmpty ? widget.hint : widget.controller.text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: widget.controller.text.isEmpty
                      ? ContraTheme.muted
                      : ContraTheme.ink,
                ),
              ),
            ),
            if (widget.suffix.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  widget.suffix,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ContraTheme.ink,
                  ),
                ),
              ),
            const Icon(Icons.keyboard_alt_rounded, color: ContraTheme.teal, size: 22),
          ],
        ),
      ),
    );
  }

  void _openKeyboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _KeyboardSheet(
        controller: widget.controller,
        numeric: widget.numeric,
      ),
    );
  }
}

class _KeyboardSheet extends StatefulWidget {
  final TextEditingController controller;
  final bool numeric;
  const _KeyboardSheet({required this.controller, required this.numeric});

  @override
  State<_KeyboardSheet> createState() => _KeyboardSheetState();
}

class _KeyboardSheetState extends State<_KeyboardSheet> {
  bool _shift = false;

  void _insert(String char) {
    final t = widget.controller.text;
    final sel = widget.controller.selection;
    if (sel.isValid && sel.start != sel.end) {
      widget.controller.text = t.replaceRange(sel.start, sel.end, char);
    } else {
      widget.controller.text = t + char;
    }
    setState(() {
      if (_shift) _shift = false;
    });
  }

  void _backspace() {
    final t = widget.controller.text;
    if (t.isNotEmpty) {
      widget.controller.text = t.substring(0, t.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = widget.numeric ? 300.0 : 360.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: widget.numeric
            ? _buildNumeric()
            : _buildAlpha(),
      ),
    );
  }

  Widget _buildNumeric() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final key in row) Expanded(child: _Key(key, onTap: () => _insert(key))),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(flex: 2, child: _Key('Space', onTap: () => _insert(' '))),
            Expanded(flex: 1, child: _Key('⌫', color: ContraTheme.yellow, onTap: _backspace)),
            Expanded(flex: 2, child: _Key('Done', color: ContraTheme.green, onTap: () => Navigator.pop(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildAlpha() {
    const numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '+'];
    const row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    const row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    const row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

    String label(String c) => _shift ? c : c.toLowerCase();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              for (final c in numbers)
                Expanded(child: _Key(c, onTap: () => _insert(c))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(children: [for (final c in row1) Expanded(child: _Key(label(c), onTap: () => _insert(label(c))))]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(children: [for (final c in row2) Expanded(child: _Key(label(c), onTap: () => _insert(label(c))))]),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              _Key('⇧', color: _shift ? ContraTheme.teal : ContraTheme.muted, onTap: () => setState(() => _shift = !_shift)),
              for (final c in row3) Expanded(child: _Key(label(c), onTap: () => _insert(label(c)))),
              _Key('⌫', color: ContraTheme.yellow, onTap: _backspace),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(flex: 2, child: _Key('Space', onTap: () => _insert(' '))),
            Expanded(flex: 2, child: _Key('Done', color: ContraTheme.green, onTap: () => Navigator.pop(context))),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Key(this.label, {required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: color ?? ContraTheme.bg,
        borderRadius: BorderRadius.circular(10),
        child: LongTap(
          onActivate: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color == null ? ContraTheme.ink : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
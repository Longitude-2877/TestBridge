import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/contra_theme.dart';

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
    return GestureDetector(
      onTap: () => _openKeyboard(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ContraTheme.card,
          border: Border.all(color: ContraTheme.border, width: 2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.controller.text.isEmpty
                    ? widget.hint
                    : widget.controller.text,
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
            const Icon(Icons.keyboard_alt_rounded,
                color: ContraTheme.blue, size: 22),
          ],
        ),
      ),
    );
  }

  void _openKeyboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _HorizontalKeyboardPage(
          controller: widget.controller,
          numeric: widget.numeric,
        ),
      ),
    );
  }
}

/// Requirement 8: a large keyboard the user turns the phone sideways to use.
/// Top row shows what is being typed, a number row, big alphabet keys with
/// symbols available on long press, shift, space, backspace and enter.
class _HorizontalKeyboardPage extends StatefulWidget {
  final TextEditingController controller;
  final bool numeric;
  const _HorizontalKeyboardPage(
      {required this.controller, required this.numeric});

  @override
  State<_HorizontalKeyboardPage> createState() =>
      _HorizontalKeyboardPageState();
}

class _HorizontalKeyboardPageState extends State<_HorizontalKeyboardPage> {
  bool _shift = false;

  static const _numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  static const _row1 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
  static const _row2 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  static const _row3 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  // Symbol shown when a key is long-pressed.
  static const Map<String, String> _symbols = {
    '1': '!', '2': '@', '3': '#', '4': r'$', '5': '%',
    '6': '^', '7': '&', '8': '*', '9': '(', '0': ')',
    'q': '?', 'w': '!', 'e': '"', 'r': "'", 't': ':', 'y': ';',
    'u': '(', 'i': ')', 'o': '[', 'p': ']',
    'a': '{', 's': '}', 'd': '<', 'f': '>', 'g': '=', 'h': '+',
    'j': '-', 'k': '*', 'l': '/',
    'z': r'\', 'x': '|', 'c': ',', 'v': '.', 'b': '`', 'n': '~', 'm': '^',
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _insert(String char) {
    final t = widget.controller.text;
    final sel = widget.controller.selection;
    if (sel.isValid && sel.start != sel.end) {
      widget.controller.text = t.replaceRange(sel.start, sel.end, char);
    } else {
      widget.controller.text = t + char;
    }
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
    if (_shift) setState(() => _shift = false);
  }

  void _backspace() {
    final t = widget.controller.text;
    if (t.isNotEmpty) {
      widget.controller.text = t.substring(0, t.length - 1);
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    }
  }

  String _label(String c) => _shift ? c.toUpperCase() : c;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContraTheme.bg,
      body: SafeArea(
        child: widget.numeric ? _buildNumeric() : _buildAlpha(),
      ),
    );
  }

  Widget _buildNumeric() {
    return Column(
      children: [
        _TypedRow(controller: widget.controller),
        Expanded(
          child: GridView.count(
            crossAxisCount: 5,
            padding: const EdgeInsets.all(10),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final k in _numbers) _Key(k, onTap: () => _insert(k)),
              _Key('Space', onTap: () => _insert(' ')),
              _Key('⌫', color: ContraTheme.yellow, onTap: _backspace),
              _Key('Enter', color: ContraTheme.green, onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlpha() {
    return Column(
      children: [
        _TypedRow(controller: widget.controller),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Expanded(
                  child: Row(children: [
                    for (final c in _numbers)
                      Expanded(
                        child: _Key(
                          c,
                          onTap: () => _insert(c),
                          onLong: _symbols[c] != null
                              ? () => _insert(_symbols[c]!)
                              : null,
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(children: [
                    for (final c in _row1)
                      Expanded(
                        child: _Key(
                          _label(c),
                          onTap: () => _insert(_label(c)),
                          onLong: _symbols[c] != null
                              ? () => _insert(_symbols[c]!)
                              : null,
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(children: [
                    for (final c in _row2)
                      Expanded(
                        child: _Key(
                          _label(c),
                          onTap: () => _insert(_label(c)),
                          onLong: _symbols[c] != null
                              ? () => _insert(_symbols[c]!)
                              : null,
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      _Key('⇧',
                          color: _shift ? ContraTheme.blue : ContraTheme.muted,
                          onTap: () => setState(() => _shift = !_shift)),
                      for (final c in _row3)
                        Expanded(
                          child: _Key(
                            _label(c),
                            onTap: () => _insert(_label(c)),
                            onLong: _symbols[c] != null
                                ? () => _insert(_symbols[c]!)
                                : null,
                          ),
                        ),
                      _Key('⌫', color: ContraTheme.yellow, onTap: _backspace),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: _Key('Space', onTap: () => _insert(' '))),
                    Expanded(
                        flex: 2,
                        child: _Key('Enter',
                            color: ContraTheme.green,
                            onTap: () => Navigator.pop(context))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TypedRow extends StatelessWidget {
  final TextEditingController controller;
  const _TypedRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: ContraTheme.card,
        border: Border.all(color: ContraTheme.border, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        controller.text.isEmpty ? 'Type here…' : controller.text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: controller.text.isEmpty ? ContraTheme.muted : ContraTheme.ink,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLong;
  final Color? color;
  const _Key(this.label,
      {required this.onTap, this.onLong, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: color ?? ContraTheme.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLong,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
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

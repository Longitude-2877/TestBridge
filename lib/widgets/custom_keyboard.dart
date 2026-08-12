import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _openKeyboard(BuildContext context) async {
    // System-wide landscape keyboard: rotate the phone to use it.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      return;
    }
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _KeyboardScreen(
            controller: widget.controller,
            numeric: widget.numeric,
          ),
        ),
      );
    } finally {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
    }
  }
}

class _KeyboardScreen extends StatefulWidget {
  final TextEditingController controller;
  final bool numeric;
  const _KeyboardScreen({required this.controller, required this.numeric});

  @override
  State<_KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<_KeyboardScreen> {
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

  void _finish() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContraTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _PreviewRow(controller: widget.controller),
              const SizedBox(height: 8),
              Expanded(
                child: widget.numeric ? _buildNumeric() : _buildAlpha(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumeric() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['+', '0', '#'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final key in row) Expanded(child: _Key(key, onActivate: () => _insert(key))),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(flex: 1, child: _Key('⌫', color: ContraTheme.yellow, onActivate: _backspace)),
            Expanded(flex: 2, child: _Key('Enter', color: ContraTheme.green, onActivate: _finish)),
          ],
        ),
      ],
    );
  }

  Widget _buildAlpha() {
    const numbers = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    const row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    const row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    const row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];
    const symbols = {
      'Q': '!', 'W': '?', 'E': '+', 'R': '(', 'T': ')', 'Y': '-', 'U': '_',
      'I': '/', 'O': ';', 'P': "'",
      'A': '@', 'S': '#', 'D': '\$', 'F': '%', 'G': '&', 'H': '*', 'J': '=',
      'K': ':', 'L': ',',
      'Z': '{', 'X': '}', 'C': '[', 'V': ']', 'B': '.', 'N': '<', 'M': '>',
    };

    String label(String c) => _shift ? c : c.toLowerCase();

Widget letterKey(String c) => _Key(
      label(c),
      showSymbol: symbols[c],
      onActivate: () => _insert(label(c)),
      onSymbol: () {
        _backspace();
        _insert(symbols[c]!);
      },
    );

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              for (final c in numbers)
                Expanded(child: _Key(c, onActivate: () => _insert(c))),
              Expanded(child: _Key('+', onActivate: () => _insert('+'))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(children: [for (final c in row1) Expanded(child: letterKey(c))]),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(children: [for (final c in row2) Expanded(child: letterKey(c))]),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Row(
            children: [
              _Key('⇧', color: _shift ? ContraTheme.teal : ContraTheme.muted, onActivate: () => setState(() => _shift = !_shift)),
              for (final c in row3) Expanded(child: letterKey(c)),
              _Key('⌫', color: ContraTheme.yellow, onActivate: _backspace),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(flex: 2, child: _Key('Space', onActivate: () => _insert(' '))),
            Expanded(flex: 1, child: _Key('Enter', color: ContraTheme.green, onActivate: _finish)),
          ],
        ),
      ],
    );
  }
}

class _PreviewRow extends StatefulWidget {
  final TextEditingController controller;
  const _PreviewRow({required this.controller});

  @override
  State<_PreviewRow> createState() => _PreviewRowState();
}

class _PreviewRowState extends State<_PreviewRow> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: ContraTheme.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                text.isEmpty ? 'Type here...' : text,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: text.isEmpty ? ContraTheme.muted : ContraTheme.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: ContraTheme.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final VoidCallback onActivate;
  final VoidCallback? onSymbol;
  final String? showSymbol;
  final Color? color;
  const _Key(
    this.label, {
    required this.onActivate,
    this.onSymbol,
    this.showSymbol,
    this.color,
  });

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  Timer? _symbolTimer;

  @override
  void dispose() {
    _symbolTimer?.cancel();
    super.dispose();
  }

  Widget _text(Color textColor, double fontSize) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        if (widget.showSymbol != null)
          Positioned(
            right: 6,
            bottom: 3,
            child: Text(
              widget.showSymbol!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? ContraTheme.card;
    final textColor = widget.color == null ? ContraTheme.ink : Colors.white;

    Widget inner;
    if (widget.onSymbol != null) {
      // Press and hold: the letter. Hold even longer (1.2s): the symbol.
      inner = GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Press longer',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
              duration: Duration(milliseconds: 900),
            ));
        },
        onLongPressStart: (_) {
          _symbolTimer?.cancel();
          _symbolTimer = Timer(const Duration(milliseconds: 1200), () {
            widget.onSymbol?.call();
          });
        },
        onLongPress: widget.onActivate,
        onLongPressEnd: (_) => _symbolTimer?.cancel(),
        onLongPressCancel: () => _symbolTimer?.cancel(),
        onLongPressUp: () => _symbolTimer?.cancel(),
        child: _text(textColor, 26),
      );
    } else {
      inner = LongTap(
        onActivate: widget.onActivate,
        child: _text(textColor, widget.label.length > 3 ? 20 : 26),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: inner,
      ),
    );
  }
}
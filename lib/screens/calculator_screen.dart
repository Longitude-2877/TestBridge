import 'package:flutter/material.dart';
import '../theme/contra_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  double? _firstOperand;
  String? _operator;
  bool _isNewNumber = true;

  void _appendDigit(String d) {
    setState(() {
      if (_isNewNumber) {
        _display = d;
        _isNewNumber = false;
      } else {
        if (_display == '0') {
          _display = d;
        } else {
          _display += d;
        }
      }
    });
  }

  void _appendDot() {
    setState(() {
      if (_isNewNumber) {
        _display = '0.';
        _isNewNumber = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0' || _display == 'Error') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _chooseOperator(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _isNewNumber = true;
    });
  }

  void _equals() {
    setState(() {
      final second = double.tryParse(_display) ?? 0;
      if (_firstOperand != null && _operator != null) {
        double result = 0;
        switch (_operator) {
          case '+':
            result = _firstOperand! + second;
            break;
          case '-':
            result = _firstOperand! - second;
            break;
          case 'x':
            result = _firstOperand! * second;
            break;
          case '/':
            result = second == 0 ? double.nan : _firstOperand! / second;
            break;
        }
        if (result.isNaN || result.isInfinite) {
          _display = 'Error';
        } else {
          _display = result == result.roundToDouble()
              ? result.toStringAsFixed(0)
              : result.toString();
        }
        _firstOperand = null;
        _operator = null;
        _isNewNumber = true;
      }
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _firstOperand = null;
      _operator = null;
      _isNewNumber = true;
    });
  }

  void _backspace() {
    setState(() {
      if (_isNewNumber) return;
      _display = _display.length > 1
          ? _display.substring(0, _display.length - 1)
          : '0';
    });
  }

  Widget _opKey(String op) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: _Key(
          op,
          color: ContraTheme.teal,
          onTap: () => _chooseOperator(op),
          fontSize: 30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: ContraTheme.card,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _operator == null && _firstOperand == null
                      ? ' '
                      : '${_firstOperand?.toStringAsFixed(0) ?? ''} $_operator',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ContraTheme.muted,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: ContraTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Expanded(
                        child: _KeyRow([
                          _Key('C', color: ContraTheme.red, onTap: _clear),
                          _Key('⌫', color: ContraTheme.muted, onTap: _backspace),
                          _Key('±', color: ContraTheme.muted, onTap: _toggleSign),
                        ]),
                      ),
                      Expanded(
                        child: _KeyRow([
                          _Key('7', onTap: () => _appendDigit('7')),
                          _Key('8', onTap: () => _appendDigit('8')),
                          _Key('9', onTap: () => _appendDigit('9')),
                        ]),
                      ),
                      Expanded(
                        child: _KeyRow([
                          _Key('4', onTap: () => _appendDigit('4')),
                          _Key('5', onTap: () => _appendDigit('5')),
                          _Key('6', onTap: () => _appendDigit('6')),
                        ]),
                      ),
                      Expanded(
                        child: _KeyRow([
                          _Key('1', onTap: () => _appendDigit('1')),
                          _Key('2', onTap: () => _appendDigit('2')),
                          _Key('3', onTap: () => _appendDigit('3')),
                        ]),
                      ),
                      Expanded(
                        child: _KeyRow([
                          _Key('0', onTap: () => _appendDigit('0')),
                          _Key('00', onTap: () => _appendDigit('00')),
                          _Key('.', onTap: _appendDot),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _opKey('/'),
                      _opKey('x'),
                      _opKey('-'),
                      _opKey('+'),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: _Key(
                            '=',
                            color: ContraTheme.green,
                            onTap: _equals,
                            fontSize: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  final List<_Key> keys;
  const _KeyRow(this.keys);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          for (final k in keys)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: k,
              ),
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;
  final double fontSize;
  const _Key(
    this.label, {
    this.color,
    required this.onTap,
    this.fontSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? ContraTheme.card;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color == null ? ContraTheme.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Display',
      ),
      home: const CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculationHistory {
  final String expression;
  final String result;
  final DateTime timestamp;

  CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
  });
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with TickerProviderStateMixin {
  String _display = '0';
  double _firstOperand = 0;
  double _secondOperand = 0;
  String _operator = '';
  bool _shouldClearDisplay = false;
  String _expression = '';
  List<CalculationHistory> _history = [];
  bool _isHistoryVisible = false;
  bool _isScientificMode = false;
  bool _isRadianMode = true; // true for radians, false for degrees
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _clear();
      } else if (value == '⌫') {
        _backspace();
      } else if (value == '=') {
        _calculate();
      } else if (['+', '-', '×', '÷', '^'].contains(value)) {
        _setOperator(value);
      } else if (value == '.') {
        _addDecimal();
      } else if (value == '±') {
        _toggleSign();
      } else if (value == '%') {
        _percentage();
      } else if (value == 'H') {
        _toggleHistory();
      } else if (value == 'SCI') {
        _toggleScientificMode();
      } else if (value == 'RAD' || value == 'DEG') {
        _toggleAngleMode();
      } else if (['sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'log', 'ln', '√', 'x²', 'x³'].contains(value)) {
        _calculateScientific(value);
      } else if (value == 'π') {
        _insertConstant(math.pi);
      } else if (value == 'e') {
        _insertConstant(math.e);
      } else {
        _addDigit(value);
      }
    });
  }

  void _clear() {
    _display = '0';
    _firstOperand = 0;
    _secondOperand = 0;
    _operator = '';
    _shouldClearDisplay = false;
    _expression = '';
  }

  void _backspace() {
    if (_display.length > 1) {
      _display = _display.substring(0, _display.length - 1);
    } else {
      _display = '0';
    }
  }

  void _addDigit(String digit) {
    if (_shouldClearDisplay) {
      _display = digit;
      _shouldClearDisplay = false;
    } else {
      _display = _display == '0' ? digit : _display + digit;
    }
  }

  void _addDecimal() {
    if (_shouldClearDisplay) {
      _display = '0.';
      _shouldClearDisplay = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
  }

  void _setOperator(String operator) {
    if (_operator.isNotEmpty && !_shouldClearDisplay) {
      _calculate();
    }

    _firstOperand = double.parse(_display);
    _operator = operator;
    _expression = '$_display $operator';
    _shouldClearDisplay = true;
  }

  void _calculate() {
    if (_operator.isEmpty) return;

    _secondOperand = double.parse(_display);
    double result = 0;
    String fullExpression = '$_firstOperand $_operator $_secondOperand';

    switch (_operator) {
      case '+':
        result = _firstOperand + _secondOperand;
        break;
      case '-':
        result = _firstOperand - _secondOperand;
        break;
      case '×':
        result = _firstOperand * _secondOperand;
        break;
      case '÷':
        if (_secondOperand != 0) {
          result = _firstOperand / _secondOperand;
        } else {
          _display = 'Error';
          _clear();
          return;
        }
        break;
      case '^':
        result = math.pow(_firstOperand, _secondOperand).toDouble();
        break;
    }

    String formattedResult = _formatResult(result);

    // Add to history
    _history.insert(0, CalculationHistory(
      expression: fullExpression,
      result: formattedResult,
      timestamp: DateTime.now(),
    ));

    _display = formattedResult;
    _expression = '';
    _operator = '';
    _shouldClearDisplay = true;
  }

  void _calculateScientific(String function) {
    double value = double.parse(_display);
    double result = 0;
    String expression = '$function($_display)';

    try {
      switch (function) {
        case 'sin':
          result = math.sin(_isRadianMode ? value : _degreesToRadians(value));
          break;
        case 'cos':
          result = math.cos(_isRadianMode ? value : _degreesToRadians(value));
          break;
        case 'tan':
          result = math.tan(_isRadianMode ? value : _degreesToRadians(value));
          break;
        case 'asin':
          result = math.asin(value);
          if (!_isRadianMode) result = _radiansToDegrees(result);
          break;
        case 'acos':
          result = math.acos(value);
          if (!_isRadianMode) result = _radiansToDegrees(result);
          break;
        case 'atan':
          result = math.atan(value);
          if (!_isRadianMode) result = _radiansToDegrees(result);
          break;
        case 'log':
          if (value > 0) {
            result = math.log(value) / math.ln10;
          } else {
            _display = 'Error';
            return;
          }
          break;
        case 'ln':
          if (value > 0) {
            result = math.log(value);
          } else {
            _display = 'Error';
            return;
          }
          break;
        case '√':
          if (value >= 0) {
            result = math.sqrt(value);
          } else {
            _display = 'Error';
            return;
          }
          break;
        case 'x²':
          result = math.pow(value, 2).toDouble();
          expression = '($_display)²';
          break;
        case 'x³':
          result = math.pow(value, 3).toDouble();
          expression = '($_display)³';
          break;
      }

      String formattedResult = _formatResult(result);

      // Add to history
      _history.insert(0, CalculationHistory(
        expression: expression,
        result: formattedResult,
        timestamp: DateTime.now(),
      ));

      _display = formattedResult;
      _shouldClearDisplay = true;
    } catch (e) {
      _display = 'Error';
    }
  }

  void _insertConstant(double constant) {
    String formattedConstant = _formatResult(constant);
    if (_shouldClearDisplay || _display == '0') {
      _display = formattedConstant;
      _shouldClearDisplay = false;
    } else {
      _display += formattedConstant;
    }
  }

  void _toggleSign() {
    if (_display != '0') {
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    }
  }

  void _percentage() {
    double value = double.parse(_display);
    value = value / 100;
    _display = _formatResult(value);
  }

  void _toggleHistory() {
    setState(() {
      _isHistoryVisible = !_isHistoryVisible;
      if (_isHistoryVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleScientificMode() {
    setState(() {
      _isScientificMode = !_isScientificMode;
    });
  }

  void _toggleAngleMode() {
    setState(() {
      _isRadianMode = !_isRadianMode;
    });
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _useHistoryValue(String value) {
    setState(() {
      _display = value;
      _shouldClearDisplay = true;
      _toggleHistory();
    });
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double _radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  String _formatResult(double result) {
    if (result.isNaN || result.isInfinite) {
      return 'Error';
    }
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toStringAsFixed(8).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with title and controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // History Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _toggleHistory,
                          icon: Icon(
                            Icons.history,
                            color: _isHistoryVisible ? const Color(0xFF3182CE) : const Color(0xFF4A5568),
                            size: 24,
                          ),
                          tooltip: 'History',
                        ),
                      ),
                      // Title
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _isScientificMode ? 'Scientific Calculator' : 'Calculator',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      // Scientific Mode Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: _isScientificMode ? const Color(0xFF3182CE) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _toggleScientificMode,
                          icon: Icon(
                            Icons.functions,
                            color: _isScientificMode ? Colors.white : const Color(0xFF4A5568),
                            size: 24,
                          ),
                          tooltip: 'Scientific Mode',
                        ),
                      ),
                    ],
                  ),
                ),
                // Display Area
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Angle mode indicator for scientific mode
                        if (_isScientificMode)
                          Container(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3182CE).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _isRadianMode ? 'RAD' : 'DEG',
                                    style: const TextStyle(
                                      color: Color(0xFF3182CE),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Expression Display
                        if (_expression.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _expression,
                              style: const TextStyle(
                                color: Color(0xFF718096),
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        // Main Display
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _display,
                            style: const TextStyle(
                              color: Color(0xFF1A202C),
                              fontSize: 62,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons Area
                Expanded(
                  flex: _isScientificMode ? 4 : 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _isScientificMode ? _buildScientificButtons() : _buildBasicButtons(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
            // History Panel
            if (_isHistoryVisible)
              GestureDetector(
                onTap: _toggleHistory,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const SizedBox.expand(),
                ),
              ),
            SlideTransition(
              position: _slideAnimation,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // History Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Row(
                                children: [
                                  if (_history.isNotEmpty)
                                    TextButton(
                                      onPressed: _clearHistory,
                                      child: const Text(
                                        'Clear',
                                        style: TextStyle(
                                          color: Color(0xFFE53E3E),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: _toggleHistory,
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xFF4A5568),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // History List
                        Expanded(
                          child: _history.isEmpty
                              ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Color(0xFFCBD5E0),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No calculations yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF718096),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                              : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _history.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.expression,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF4A5568),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(item.timestamp),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF718096),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '= ${item.result}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Color(0xFF2D3748),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => _useHistoryValue(item.result),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Use',
                                            style: TextStyle(
                                              color: Color(0xFF3182CE),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildBasicButtons() {
    return Column(
      children: [
        // Row 1
        Expanded(
          child: Row(
            children: [
              _buildButton('C', const Color(0xFFE53E3E), Colors.white, ButtonType.function),
              _buildButton('±', const Color(0xFF4A5568), Colors.white, ButtonType.function),
              _buildButton('%', const Color(0xFF4A5568), Colors.white, ButtonType.function),
              _buildButton('÷', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 2
        Expanded(
          child: Row(
            children: [
              _buildButton('7', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('8', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('9', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('×', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 3
        Expanded(
          child: Row(
            children: [
              _buildButton('4', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('5', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('6', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('-', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 4
        Expanded(
          child: Row(
            children: [
              _buildButton('1', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('2', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('3', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('+', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 5
        Expanded(
          child: Row(
            children: [
              _buildButton('0', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number, flex: 2),
              _buildButton('.', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('=', const Color(0xFF38A169), Colors.white, ButtonType.equals),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScientificButtons() {
    return Column(
      children: [
        // Row 1 - Scientific functions
        Expanded(
          child: Row(
            children: [
              _buildButton(_isRadianMode ? 'RAD' : 'DEG', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('sin', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('cos', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('tan', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('log', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
            ],
          ),
        ),
        // Row 2 - More scientific functions
        Expanded(
          child: Row(
            children: [
              _buildButton('^', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
              _buildButton('asin', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('acos', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('atan', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('ln', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
            ],
          ),
        ),
        // Row 3 - Constants and functions
        Expanded(
          child: Row(
            children: [
              _buildButton('π', const Color(0xFF38B2AC), Colors.white, ButtonType.function),
              _buildButton('e', const Color(0xFF38B2AC), Colors.white, ButtonType.function),
              _buildButton('√', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('x²', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
              _buildButton('x³', const Color(0xFF9F7AEA), Colors.white, ButtonType.function),
            ],
          ),
        ),
        // Row 4 - Basic operations
        Expanded(
          child: Row(
            children: [
              _buildButton('C', const Color(0xFFE53E3E), Colors.white, ButtonType.function),
              _buildButton('⌫', const Color(0xFF4A5568), Colors.white, ButtonType.function),
              _buildButton('%', const Color(0xFF4A5568), Colors.white, ButtonType.function),
              _buildButton('±', const Color(0xFF4A5568), Colors.white, ButtonType.function),
              _buildButton('÷', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 5 - Numbers and operators
        Expanded(
          child: Row(
            children: [
              _buildButton('7', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('8', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('9', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('×', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 6
        Expanded(
          child: Row(
            children: [
              _buildButton('4', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('5', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('6', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('-', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 7
        Expanded(
          child: Row(
            children: [
              _buildButton('1', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('2', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('3', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('+', const Color(0xFF3182CE), Colors.white, ButtonType.operator),
            ],
          ),
        ),
        // Row 8
        Expanded(
          child: Row(
            children: [
              _buildButton('0', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number, flex: 2),
              _buildButton('.', const Color(0xFFEDF2F7), const Color(0xFF2D3748), ButtonType.number),
              _buildButton('=', const Color(0xFF38A169), Colors.white, ButtonType.equals),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, Color backgroundColor, Color textColor, ButtonType type, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.all(4),
        height: _isScientificMode ? 55 : 70,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _onButtonPressed(text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_isScientificMode ? 16 : 20),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_isScientificMode ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor == const Color(0xFFEDF2F7)
                      ? Colors.black.withOpacity(0.05)
                      : backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: _getFontSize(text, type),
                  fontWeight: _getFontWeight(type),
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getFontSize(String text, ButtonType type) {
    if (_isScientificMode) {
      if (text.length > 3) return 12;
      if (['sin', 'cos', 'tan', 'log', 'RAD', 'DEG'].contains(text)) return 14;
      if (['asin', 'acos', 'atan'].contains(text)) return 12;
      return 16;
    }

    if (text == '0') return 32;
    if (type == ButtonType.operator || type == ButtonType.equals) return 32;
    return 28;
  }

  FontWeight _getFontWeight(ButtonType type) {
    switch (type) {
      case ButtonType.number:
        return FontWeight.w500;
      case ButtonType.operator:
      case ButtonType.equals:
        return FontWeight.w600;
      case ButtonType.function:
        return FontWeight.w600;
    }
  }
}

enum ButtonType {
  number,
  operator,
  function,
  equals,
}
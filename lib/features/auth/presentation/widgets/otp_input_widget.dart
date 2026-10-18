import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget Input OTP 6 Kotak Interaktif
class OtpInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpInputWidget({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpInputWidget> createState() => OtpInputWidgetState();
}

class OtpInputWidgetState extends State<OtpInputWidget> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (int i = 0; i < widget.length; i++) {
      _focusNodes[i].addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get otpCode {
    return _controllers.map((c) => c.text).join();
  }

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
    if (mounted) setState(() {});
  }

  void _handleChanged(int index, String value) {
    // 1. Dukungan Paste (Jika pengguna menempel teks 6 angka)
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= widget.length) {
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes.last.requestFocus();
      final fullOtp = digits.substring(0, widget.length);
      widget.onChanged?.call(fullOtp);
      widget.onCompleted?.call(fullOtp);
      setState(() {});
      return;
    }

    // 2. Normal input per kotak
    if (value.isNotEmpty) {
      // Ambil karakter terakhir jika pengguna mengetik di kotak yang sudah ada isinya
      final char = value.substring(value.length - 1);
      _controllers[index].text = char;
      _controllers[index].selection = TextSelection.collapsed(offset: 1);

      // Pindah otomatis ke kotak berikutnya
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final currentOtp = otpCode;
    widget.onChanged?.call(currentOtp);
    if (currentOtp.length == widget.length) {
      widget.onCompleted?.call(currentOtp);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final isFilled = _controllers[index].text.isNotEmpty;

        return Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.5),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_controllers[index].text.isEmpty && index > 0) {
                    _focusNodes[index - 1].requestFocus();
                    _controllers[index - 1].clear();
                    widget.onChanged?.call(otpCode);
                    setState(() {});
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 56,
                decoration: BoxDecoration(
                  color: isFocused
                      ? const Color(0xFFFDF8F5)
                      : (isFilled ? Colors.white : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : (isFilled
                            ? AppColors.primaryLight.withValues(alpha: 0.6)
                            : const Color(0xFFCBD5E1)),
                    width: isFocused ? 2.0 : 1.2,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    cursorColor: AppColors.primary,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) => _handleChanged(index, val),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

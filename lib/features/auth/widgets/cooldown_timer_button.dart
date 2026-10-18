import 'dart:async';

import 'package:flutter/material.dart';

import '../../../components/ui/app_button.dart';
import '../../../theme/app_typography.dart';

class CooldownTimerButton extends StatefulWidget {
  const CooldownTimerButton({
    super.key,
    required this.onResend,
    this.initialCooldownSeconds = 60,
    this.startActive = true,
  });

  final Future<bool> Function() onResend;
  final int initialCooldownSeconds;
  final bool startActive;

  @override
  State<CooldownTimerButton> createState() => _CooldownTimerButtonState();
}

class _CooldownTimerButtonState extends State<CooldownTimerButton> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.startActive ? widget.initialCooldownSeconds : 0;
    if (_remainingSeconds > 0) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handlePressed() async {
    if (_remainingSeconds > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final success = await widget.onResend();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _remainingSeconds = widget.initialCooldownSeconds;
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingSeconds > 0) {
      final minutes = _remainingSeconds ~/ 60;
      final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFECEBE7),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'Resend link in $minutes:$seconds',
          style: AppTypography.body(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA3A3A8),
          ),
        ),
      );
    }

    return AppButton(
      text: 'Resend link',
      variant: AppButtonVariant.secondary,
      isFullWidth: true,
      isLoading: _isLoading,
      onPressed: _handlePressed,
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.hasError = false,
    this.child,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool hasError;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: value ? colors.primary : colors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value
              ? colors.primary
              : (hasError ? colors.destructive : colors.input),
          width: 1.5,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );

    if (child == null) {
      return Semantics(
        checked: value,
        child: InkWell(
          onTap: onChanged != null ? () => onChanged!(!value) : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(11), // 22 + 22 = 44px tap target
            child: box,
          ),
        ),
      );
    }

    return Semantics(
      checked: value,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 10),
                child: box,
              ),
              Expanded(child: child!),
            ],
          ),
        ),
      ),
    );
  }
}

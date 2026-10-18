import 'package:flutter/material.dart';

import '../../../theme/app_typography.dart';

class PasswordCriteriaChips extends StatelessWidget {
  const PasswordCriteriaChips({super.key, required this.password});

  final String password;

  static bool hasMinLength(String p) => p.length >= 8 && p.length <= 64;
  static bool hasUpper(String p) => p.contains(RegExp(r'[A-Z]'));
  static bool hasLower(String p) => p.contains(RegExp(r'[a-z]'));
  static bool hasNumber(String p) => p.contains(RegExp(r'[0-9]'));
  static bool hasSpecial(String p) =>
      p.contains(RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/`~]'''));

  static bool allCriteriaMet(String p) =>
      hasMinLength(p) &&
      hasUpper(p) &&
      hasLower(p) &&
      hasNumber(p) &&
      hasSpecial(p);

  @override
  Widget build(BuildContext context) {
    final col1 = [
      _CriterionItem(label: '8–64 characters', isMet: hasMinLength(password)),
      _CriterionItem(label: 'A lower case letter', isMet: hasLower(password)),
      _CriterionItem(label: 'A special character', isMet: hasSpecial(password)),
    ];

    final col2 = [
      _CriterionItem(label: 'An upper case letter', isMet: hasUpper(password)),
      _CriterionItem(label: 'A number', isMet: hasNumber(password)),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: col1
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildChip(item),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: col2
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildChip(item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(_CriterionItem item) {
    if (item.isMet) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5EE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check, size: 11, color: Color(0xFF12764A)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              item.label,
              style: AppTypography.body(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF12764A),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC9C7C1), width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            item.label,
            style: AppTypography.body(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64646B),
            ),
          ),
        ),
      ],
    );
  }
}

class _CriterionItem {
  const _CriterionItem({required this.label, required this.isMet});

  final String label;
  final bool isMet;
}

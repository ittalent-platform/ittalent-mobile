import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Looks of the apply screens that the shared tokens do not name, derived
/// from them so that both themes follow.
extension ApplyColors on AppColors {
  /// The outline of radios and checkboxes: a step darker than an input's.
  Color get control =>
      Color.alphaBlend(mutedForeground.withValues(alpha: 0.18), input);

  /// The fill of a chosen option: a hint of the brand colour.
  Color get chosen => Color.alphaBlend(primary.withValues(alpha: 0.04), card);

  /// The fill of a brand-coloured pill ("Default CV").
  Color get brandTint =>
      Color.alphaBlend(primary.withValues(alpha: 0.12), card);
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Renders characters and hidden blank blanks for secret gameplay words.
class SWWordDisplay extends StatelessWidget {
  /// Creates an [SWWordDisplay].
  const SWWordDisplay({
    required this.word,
    required this.revealedIndices,
    super.key,
  });

  /// The complete word (e.g. 'STRIKE').
  final String word;

  /// List of character indices that are revealed (unmasked).
  final List<int> revealedIndices;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(word.length, (index) {
        final char = word[index];
        final isRevealed = revealedIndices.contains(index);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: SWSpacing.xs),
          width: 24.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isRevealed ? colors.primary : colors.textMuted,
                width: 2.r,
              ),
            ),
          ),
          child: Text(
            isRevealed ? char.toUpperCase() : ' ',
            style: typography.wordPrompt.copyWith(
              fontSize: 20.sp,
              color: colors.textPrimary,
            ),
          ),
        );
      }),
    );
  }
}

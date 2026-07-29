import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_sizes.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// Supported avatar size variants.
enum SWAvatarSize {
  /// Compact user representation (36dp).
  small,

  /// Default profile card representation (54dp).
  medium,

  /// Expanded settings or result view representation (80dp).
  large,
}

/// A premium circular player avatar with fallback initials.
class SWAvatar extends StatelessWidget {
  /// Creates an [SWAvatar].
  const SWAvatar({
    required this.name,
    super.key,
    this.avatarUrl,
    this.size = SWAvatarSize.medium,
    this.backgroundColor,
  });

  /// The player display name (used to resolve fallback initials).
  final String name;

  /// Optional avatar remote image URL.
  final String? avatarUrl;

  /// Display size variant.
  final SWAvatarSize size;

  /// Custom backdrop color.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    final diameter = switch (size) {
      SWAvatarSize.small => SWSizes.avatarSmall,
      SWAvatarSize.medium => SWSizes.avatarMedium,
      SWAvatarSize.large => SWSizes.avatarLarge,
    };

    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase()
        : '?';

    final textStyle = typography.heading.copyWith(
      fontSize: (diameter / 2.5).sp,
      fontWeight: FontWeight.w900,
      color: colors.primary,
      letterSpacing: 0,
    );

    final bg = backgroundColor ?? colors.surfaceContainerHighest;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border, width: 1.5.r),
      ),
      child: ClipRRect(
        borderRadius: SWRadius.circular,
        child: avatarUrl != null && avatarUrl!.isNotEmpty
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: Text(initials, style: textStyle)),
              )
            : Center(child: Text(initials, style: textStyle)),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/shared/design_language/tokens/sw_radius.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_sizes.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';
import 'package:stroke_wars/shared/design_language/widgets/avatars/avatar_framework.dart';

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
    this.profilePicturePath,
    this.avatarId,
    this.avatarFrameId,
    this.size = SWAvatarSize.medium,
    this.backgroundColor,
  });

  /// The player display name (used to resolve fallback initials).
  final String name;

  /// Optional avatar remote image URL.
  final String? avatarUrl;

  /// Optional local disk photo image path.
  final String? profilePicturePath;

  /// Optional built-in vector avatar ID mapping.
  final String? avatarId;

  /// Optional cosmetic frame ID mapping.
  final String? avatarFrameId;

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

    // Dynamic resolution of image widget
    Widget? imageWidget;

    if (profilePicturePath != null && profilePicturePath!.isNotEmpty) {
      final file = File(profilePicturePath!);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.cover,
          width: diameter,
          height: diameter,
        );
      }
    }

    if (imageWidget == null && avatarUrl != null && avatarUrl!.isNotEmpty) {
      imageWidget = Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        width: diameter,
        height: diameter,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }

    // Default built-in vector icon lookup
    final builtInDef = avatarId != null
        ? AvatarFramework.findAvatar(avatarId!)
        : null;
    final bg =
        backgroundColor ??
        builtInDef?.color.withValues(alpha: 0.15) ??
        colors.surfaceContainerHighest;

    Widget coreAvatar = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border, width: 1.5.r),
      ),
      child: ClipRRect(
        borderRadius: SWRadius.circular,
        child:
            imageWidget ??
            (builtInDef != null
                ? Icon(
                    builtInDef.icon,
                    size: (diameter * 0.55).r,
                    color: builtInDef.color,
                  )
                : Center(child: Text(initials, style: textStyle))),
      ),
    );

    // Apply avatar cosmetic frames
    final frameDef = avatarFrameId != null
        ? AvatarFramework.findFrame(avatarFrameId!)
        : null;
    if (frameDef != null && frameDef.id != 'none') {
      coreAvatar = Container(
        padding: EdgeInsets.all(frameDef.borderWidth.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: frameDef.glowColor,
            width: frameDef.borderWidth.r,
          ),
          boxShadow: [
            BoxShadow(
              color: frameDef.glowColor.withValues(alpha: 0.3),
              blurRadius: 8.r,
              spreadRadius: 1.r,
            ),
          ],
        ),
        child: coreAvatar,
      );
    }

    return coreAvatar;
  }
}

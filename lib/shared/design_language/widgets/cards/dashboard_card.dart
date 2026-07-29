import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/features/home/domain/models/dashboard_module.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// A premium, highly animated dashboard card rendering GCC modules dynamically.
class SWDashboardCard extends StatelessWidget {
  /// Creates a [SWDashboardCard].
  const SWDashboardCard({required this.module, super.key, this.onTap});

  /// The dashboard configuration data model.
  final DashboardModule module;

  /// Trigger callback on successful interactions.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final spacing = context.swSpacing;

    final isInteractive = module.isInteractive;
    final isLocked = module.featureState == FeatureState.locked;
    final isComingSoon = module.featureState == FeatureState.comingSoon;
    final isExperimental = module.featureState == FeatureState.experimental;

    // Resolve card decoration
    final cardBorderColor = isInteractive
        ? (isExperimental ? colors.secondary : colors.border)
        : colors.border.withValues(alpha: 0.5);

    final opacity = isInteractive ? 1.0 : 0.65;

    Widget content = Opacity(
      opacity: opacity,
      child: Container(
        padding: EdgeInsets.all(spacing.md.r),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: SWRadius.l,
          border: Border.all(color: cardBorderColor, width: 1.5.r),
          boxShadow: isInteractive
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.05),
                    blurRadius: 10.r,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Glowing Icon
            Container(
              padding: EdgeInsets.all(spacing.sm.r),
              decoration: BoxDecoration(
                color: module.gradient != null
                    ? Colors.transparent
                    : colors.primary.withValues(alpha: 0.1),
                gradient: module.gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                module.icon,
                color: isInteractive ? colors.primary : colors.textMuted,
                size: 28.r,
              ),
            ),
            SizedBox(width: spacing.md),

            // Text configuration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          module.title,
                          style: typography.title.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isInteractive
                                ? colors.textPrimary
                                : colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isExperimental) ...[
                        SizedBox(width: spacing.xs),
                        SWBadge(
                          label: 'BETA',
                          color: colors.secondary.withValues(alpha: 0.15),
                          textColor: colors.secondary,
                        ),
                      ],
                      if (isComingSoon) ...[
                        SizedBox(width: spacing.xs),
                        SWBadge(
                          label: module.stage ?? 'SOON',
                          color: colors.primary.withValues(alpha: 0.15),
                          textColor: colors.primary,
                        ),
                      ],
                      if (isLocked) ...[
                        SizedBox(width: spacing.xs),
                        const Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    module.subtitle,
                    style: typography.body.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.sm),

            // Badge notifications & arrows
            if (isInteractive && module.badgeCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: colors.danger,
                  borderRadius: SWRadius.xl,
                ),
                child: Text(
                  module.badgeCount.toString(),
                  style: typography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (isInteractive)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colors.primary,
                size: 14.r,
              ),
          ],
        ),
      ),
    );

    if (isInteractive) {
      return SWPressableScale(onTap: onTap, child: content);
    }

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: content,
    );
  }
}

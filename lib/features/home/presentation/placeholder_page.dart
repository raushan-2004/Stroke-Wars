import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/home/domain/models/dashboard_module.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// Premium visual placeholder page rendered dynamically based on feature states.
class SWPlaceholderPage extends StatelessWidget {
  /// Creates a [SWPlaceholderPage] screen.
  const SWPlaceholderPage({required this.module, super.key});

  /// The dashboard configuration defining this module's placeholder state.
  final DashboardModule module;

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final spacing = context.swSpacing;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text(
          module.title.toUpperCase(),
          style: typography.heading.copyWith(letterSpacing: 1.5.w),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: spacing.lg.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large glowing neon icon representation
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2.r),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.2),
                      blurRadius: 20.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
                child: Icon(module.icon, size: 54.r, color: colors.primary),
              ),
              SizedBox(height: spacing.xl),

              // Glass container showing details
              SWGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      module.title,
                      style: typography.displayLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      module.subtitle,
                      style: typography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing.lg),
                    _buildStateBadge(context),
                  ],
                ),
              ),
              SizedBox(height: spacing.xl),

              SWButton(
                onPressed: () => Navigator.of(context).pop(),
                text: 'BACK TO COMMAND CENTER',
                variant: SWButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateBadge(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    final String badgeText;
    final Color badgeColor;

    switch (module.featureState) {
      case FeatureState.comingSoon:
        badgeText = 'COMING IN ${module.stage ?? "FUTURE STAGES"}';
        badgeColor = colors.primary;
        break;
      case FeatureState.locked:
        badgeText = 'LOCKED / REACH LEVEL 5';
        badgeColor = Colors.amber;
        break;
      case FeatureState.experimental:
        badgeText = 'EXPERIMENTAL BETA';
        badgeColor = colors.secondary;
        break;
      case FeatureState.disabled:
        badgeText = 'TEMPORARILY DISABLED';
        badgeColor = colors.danger;
        break;
      case FeatureState.enabled:
        badgeText = 'MODULE ACTIVE';
        badgeColor = colors.victory;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: SWRadius.l,
        border: Border.all(color: badgeColor, width: 1.5.r),
      ),
      child: Text(
        badgeText,
        style: typography.title.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.w,
          fontSize: 12.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

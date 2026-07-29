import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:stroke_wars/core/services/theme_service.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/home/application/navigation_service.dart';
import 'package:stroke_wars/features/home/application/notification_provider.dart';
import 'package:stroke_wars/features/home/domain/repositories/dashboard_registry.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// The Game Command Center (GCC) is the central dashboard and hub of the application.
class GameCommandCenterPage extends ConsumerWidget {
  /// Creates a [GameCommandCenterPage].
  const GameCommandCenterPage({super.key});

  void _copyPlayerId(BuildContext context, String uuid) {
    Clipboard.setData(ClipboardData(text: uuid));
    SWToast.show(context, 'Player ID copied to clipboard!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerServiceProvider);
    final registry = ref.watch(dashboardRegistryProvider);
    final navService = ref.watch(navigationServiceProvider);
    final badgeCount = ref.watch(notificationBadgeCountProvider);

    final spacing = context.swSpacing;

    if (player == null) {
      return const AppScaffold(body: Center(child: SWCircularLoading()));
    }

    // Determine grid size dynamically based on responsiveness constraints
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isTablet = mediaQuery.size.width >= 600;
    final crossAxisCount = isTablet ? 3 : (isLandscape ? 2 : 1);

    final primaryModules = registry.getPrimaryModules();
    final secondaryModules = registry.getSecondaryModules();

    return AppScaffold(
      useSafeArea: true,
      body: Stack(
        children: [
          // Background glow styling
          Positioned(
            top: -150.h,
            left: -100.w,
            right: -100.w,
            child: Container(
              height: 450.h,
              decoration: BoxDecoration(
                gradient: context.swGradients.radialGlow,
              ),
            ),
          ),

          // Main scroll feed
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.lg.r,
                vertical: spacing.md.r,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar section
                  _buildTopBar(context, badgeCount),
                  SizedBox(height: spacing.md),

                  // Player profile summary badge
                  SWPlayerSummary(
                    player: player,
                    onTap: () => navService.openProfile(context),
                  ),
                  SizedBox(height: spacing.lg),

                  // Reusable Season progress banner slot
                  _buildSeasonBanner(context),
                  SizedBox(height: spacing.lg),

                  // Primary game actions grid
                  const SWSectionHeader(title: 'Battle Modes'),
                  SizedBox(height: spacing.sm),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing.md.r,
                      mainAxisSpacing: spacing.md.r,
                      childAspectRatio: isTablet ? 2.6 : 3.0,
                    ),
                    itemCount: primaryModules.length,
                    itemBuilder: (context, index) {
                      final module = primaryModules[index];
                      return SWDashboardCard(
                        module: module,
                        onTap: () =>
                            navService.navigateToModule(context, module),
                      );
                    },
                  ),
                  SizedBox(height: spacing.lg),

                  // Reusable sections (News, Challenges)
                  _buildFeaturedChallenge(context),
                  SizedBox(height: spacing.lg),

                  // Secondary administrative options
                  const SWSectionHeader(title: 'Identity & Configuration'),
                  SizedBox(height: spacing.sm),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing.md.r,
                      mainAxisSpacing: spacing.md.r,
                      childAspectRatio: isTablet ? 3.0 : 3.4,
                    ),
                    itemCount: secondaryModules.length,
                    itemBuilder: (context, index) {
                      final module = secondaryModules[index];
                      return SWDashboardCard(
                        module: module,
                        onTap: () =>
                            navService.navigateToModule(context, module),
                      );
                    },
                  ),
                  SizedBox(height: spacing.lg),

                  // Floating quick actions row
                  _buildQuickActions(context, player.uuid),
                  SizedBox(height: spacing.gigantic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, int badgeCount) {
    final colors = context.swColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) =>
                context.swGradients.primary.createShader(bounds),
            child: Text(
              'STROKE WARS',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.w,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Row(
          children: [
            // Developer component showcase shortcut
            IconButton(
              icon: Icon(Icons.developer_mode_rounded, color: colors.primary),
              onPressed: () => refWatchShowcase(context),
              tooltip: 'Component Sandbox',
            ),
            // Dynamic theme Cycle toggle
            IconButton(
              icon: Icon(Icons.brightness_auto_rounded, color: colors.primary),
              onPressed: () {
                final container = ProviderScope.containerOf(context);
                container.read(themeModeNotifierProvider.notifier).cycleTheme();
              },
            ),
            // Notifications badge trigger placeholder
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_rounded,
                    color: colors.primary,
                  ),
                  onPressed: () =>
                      SWToast.show(context, 'Notification Panel Coming Soon!'),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 10,
                        minHeight: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Developer showcase navigate helper
  void refWatchShowcase(BuildContext context) {
    context.push('/showcase');
  }

  Widget _buildSeasonBanner(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final spacing = context.swSpacing;

    return SWGlassCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(spacing.sm.r),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: SWRadius.m,
            ),
            child: Icon(
              Icons.insights_rounded,
              color: colors.primary,
              size: 28.r,
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SEASON 0: PRE-LAUNCH',
                  style: typography.title.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Complete matches to unlock season milestones.',
                  style: typography.body.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.sm),
          const SWBadge(label: 'SOON'),
        ],
      ),
    );
  }

  Widget _buildFeaturedChallenge(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;
    final spacing = context.swSpacing;

    return SWDashboardSection(
      title: 'Daily Event',
      content: SWGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Speed Sketcher',
                    style: typography.title.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing.sm),
                Text(
                  '+500 XP',
                  style: typography.caption.copyWith(
                    color: colors.victory,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Draw a "DRAGON" and get it guessed correctly in under 5 seconds.',
              style: typography.body.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: spacing.md),
            ClipRRect(
              borderRadius: SWRadius.circular,
              child: LinearProgressIndicator(
                value: 0.0,
                minHeight: 6.h,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String uuid) {
    final colors = context.swColors;
    final spacing = context.swSpacing;

    return Container(
      padding: EdgeInsets.all(spacing.sm.r),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: SWRadius.xl,
        border: Border.all(color: colors.border, width: 1.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: () => _copyPlayerId(context, uuid),
            tooltip: 'Copy Player ID',
            color: colors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () =>
                SWToast.show(context, 'Profile Sharing Coming Soon!'),
            tooltip: 'Share Profile',
            color: colors.primary,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () =>
                SWToast.show(context, 'Friend Invites Coming Soon!'),
            tooltip: 'Invite Friend',
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}

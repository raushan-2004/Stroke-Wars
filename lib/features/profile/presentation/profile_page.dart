import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

/// Player profile page.
///
/// Stage 0: Shows a profile placeholder with avatar and stats layout.
class ProfilePage extends ConsumerWidget {
  /// Creates a [ProfilePage].
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: context.swTypography.heading.copyWith(letterSpacing: 1),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const SWIcon(SWIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: context.swSpacing.lg,
          vertical: context.swSpacing.md,
        ),
        child: Column(
          children: [
            SizedBox(height: context.swSpacing.md),
            _AvatarSection(),
            SizedBox(height: context.swSpacing.xl),
            _StatsRow(),
            SizedBox(height: context.swSpacing.xl),
            _ProfileActions(),
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Column(
      children: [
        const SWAvatarRing(
          avatar: SWAvatar(name: 'Player', size: SWAvatarSize.large),
          progress: 0.45,
          level: 4,
        ),
        SizedBox(height: context.swSpacing.md),
        Text(
          'Player',
          style: typography.displayLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: context.swSpacing.xs),
        Text(
          'Rookie Artist',
          style: typography.body.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: SWStatCard(label: 'Games', value: '42'),
        ),
        SizedBox(width: context.swSpacing.sm),
        const Expanded(
          child: SWStatCard(label: 'Wins', value: '28'),
        ),
        SizedBox(width: context.swSpacing.sm),
        const Expanded(
          child: SWStatCard(label: 'Points', value: '1.4K'),
        ),
      ],
    );
  }
}

class _ProfileActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SWButton(
          onPressed: () => SWToast.show(
            context,
            'Edit profile editing is coming in a future stage!',
          ),
          text: 'Edit Profile',
          icon: const SWIcon(Icons.edit_rounded, color: Colors.white),
        ),
        SizedBox(height: context.swSpacing.sm),
        SWButton(
          onPressed: () =>
              SWToast.show(context, 'Achievements list is coming soon!'),
          text: 'View Achievements',
          variant: SWButtonVariant.secondary,
          icon: SWIcon(SWIcons.trophy, color: context.swColors.victory),
        ),
      ],
    );
  }
}

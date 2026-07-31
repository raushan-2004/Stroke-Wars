import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/competitive/providers/competitive_providers.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class SocialHubPage extends ConsumerStatefulWidget {
  const SocialHubPage({super.key});

  @override
  ConsumerState<SocialHubPage> createState() => _SocialHubPageState();
}

class _SocialHubPageState extends ConsumerState<SocialHubPage> {
  final _inviteFriendIdController = TextEditingController();

  @override
  void dispose() {
    _inviteFriendIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialGraphServiceProvider);
    final notifications = ref.watch(activeNotificationsProvider);
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return AppScaffold(
      useSafeArea: true,
      appBar: AppBar(
        title: Text('Social Hub', style: typography.heading),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        color: colors.background,
        padding: EdgeInsets.all(spacing.md.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Friends List & Presence Simulator
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildSectionHeader(context, 'Friends List'),
                  Expanded(
                    child: ListView.builder(
                      itemCount: social.friends.length,
                      itemBuilder: (context, index) {
                        final friend = social.friends[index];
                        final isOnline = friend.presence == 'online';
                        final isIngame = friend.presence == 'ingame';

                        Color presenceColor = colors.textMuted;
                        if (isOnline) presenceColor = Colors.green;
                        if (isIngame) presenceColor = colors.primary;

                        return Padding(
                          padding: EdgeInsets.only(bottom: spacing.xs.r),
                          child: SWGlassCard(
                            child: ListTile(
                              title: Text(
                                friend.displayName,
                                style: typography.body,
                              ),
                              subtitle: Text(
                                friend.presence.toUpperCase(),
                                style: typography.caption.copyWith(
                                  color: presenceColor,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Simulation Trigger: Toggle online status
                                  IconButton(
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    tooltip: 'Simulate Presence Change',
                                    onPressed: () {
                                      setState(() {
                                        final next = friend.presence == 'online'
                                            ? 'ingame'
                                            : friend.presence == 'ingame'
                                            ? 'offline'
                                            : 'online';
                                        social.updatePresence(
                                          friend.userId,
                                          next,
                                        );
                                      });
                                    },
                                  ),
                                  if (social.currentParty != null &&
                                      friend.presence == 'online')
                                    IconButton(
                                      icon: const Icon(Icons.group_add_rounded),
                                      color: colors.primary,
                                      tooltip: 'Invite to Party',
                                      onPressed: () {
                                        social.sendPartyInvite(
                                          friend.userId,
                                          'Host Player',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Invited ${friend.displayName} to party',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: spacing.md.r),

            // Right Panel: Party status & Notifications
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // Party controller
                  _buildPartyCard(context, social),
                  SizedBox(height: spacing.md.r),

                  // Friend requests
                  _buildSectionHeader(context, 'Friend Requests'),
                  Expanded(
                    child: social.friendRequests.isEmpty
                        ? Center(
                            child: Text(
                              'No requests',
                              style: typography.caption,
                            ),
                          )
                        : ListView.builder(
                            itemCount: social.friendRequests.length,
                            itemBuilder: (context, index) {
                              final req = social.friendRequests[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: spacing.xs.r),
                                child: SWGlassCard(
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                      req.fromDisplayName,
                                      style: typography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.green,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              social.acceptFriendRequest(
                                                req.fromUserId,
                                              );
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: colors.danger,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              social.declineFriendRequest(
                                                req.fromUserId,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.swColors;
    final typography = context.swTypography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.r),
      child: Row(
        children: [
          Container(width: 4.r, height: 16.r, color: colors.primary),
          SizedBox(width: 8.r),
          Text(title, style: typography.heading.copyWith(fontSize: 16.sp)),
        ],
      ),
    );
  }

  Widget _buildPartyCard(BuildContext context, dynamic social) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;
    final party = social.currentParty;

    return SWGlassCard(
      child: Padding(
        padding: EdgeInsets.all(spacing.sm.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Party Lobby',
              style: typography.body.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing.sm),
            if (party == null) ...[
              Text(
                'Not in a party lobby.',
                style: typography.caption.copyWith(color: colors.textMuted),
              ),
              SizedBox(height: spacing.sm),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    social.createParty('host-player');
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                ),
                child: const Text('Create Party'),
              ),
            ] else ...[
              Text(
                'Party Code: ${party.partyId}',
                style: typography.caption.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: spacing.xs),
              Text(
                'Members: ${party.members.length} / 4',
                style: typography.caption,
              ),
              SizedBox(height: spacing.sm),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    social.leaveParty();
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: colors.danger),
                child: const Text('Leave Party'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/features/lan/providers/lan_providers.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class LANLobbyPage extends ConsumerWidget {
  const LANLobbyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(lANSessionStateProvider);
    final notifier = ref.watch(lANSessionStateProvider.notifier);
    final player = ref.watch(playerServiceProvider);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    if (session.room == null) {
      return const Center(child: SWCircularLoading());
    }

    final room = session.room!;
    final localPlayerId =
        notifier.controller.matchController.match?.hostId == 'host'
        ? 'host'
        : player?.uuid ?? '';
    final isHost =
        room.host.id.value == 'host' || room.host.id.value == localPlayerId;
    final localPlayerConnection = session.players.firstWhere(
      (p) =>
          p.peerInfo.id.value == localPlayerId ||
          p.peerInfo.id.value == 'host' && isHost,
      orElse: () => session.players.isNotEmpty
          ? session.players.first
          : session.players.first,
    );
    final isLocalReady = localPlayerConnection.isReady;

    // A match starts only if there are enough players and everyone (except host maybe) is ready
    final canStart =
        isHost &&
        room.players.length >= 2 &&
        room.players
            .where((p) => p.peerInfo.id.value != 'host')
            .every((p) => p.isReady);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              room.configuration.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: typography.title.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 24.sp,
                letterSpacing: 1.5.w,
              ),
            ),
            SizedBox(height: spacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lobby State • Host: ${room.host.displayName}',
                  style: typography.body.copyWith(color: colors.textMuted),
                ),
                SizedBox(width: spacing.sm),
                Icon(
                  Icons.wifi_tethering_rounded,
                  color:
                      session.connectionQuality ==
                              ConnectionQuality.excellent ||
                          session.connectionQuality == ConnectionQuality.good
                      ? colors.success
                      : colors.warning,
                  size: 16.r,
                ),
              ],
            ),
            SizedBox(height: spacing.xl),

            // PLAYERS LIST
            SWGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Players', style: typography.heading),
                      Text(
                        '${room.players.length}/${room.configuration.maxPlayers}',
                        style: typography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: session.players.length,
                    separatorBuilder: (_, __) => Divider(color: colors.border),
                    itemBuilder: (context, index) {
                      final conn = session.players[index];
                      final isConnHost =
                          conn.peerInfo.id.value == 'host' ||
                          conn.peerInfo.id.value == room.host.id.value;
                      return ListTile(
                        leading: SWAvatar(
                          name: conn.peerInfo.displayName,
                          backgroundColor: isConnHost
                              ? colors.primary.withValues(alpha: 0.15)
                              : colors.secondary.withValues(alpha: 0.15),
                        ),
                        title: Row(
                          children: [
                            Text(
                              conn.peerInfo.displayName,
                              style: typography.body.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isConnHost) ...[
                              SizedBox(width: spacing.xs),
                              SWBadge(label: 'Host', color: colors.primary),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          conn.connectionState.name.toUpperCase(),
                          style: typography.caption.copyWith(
                            color: conn.connectionState.name == 'connected'
                                ? colors.success
                                : colors.danger,
                          ),
                        ),
                        trailing: conn.isReady
                            ? SWBadge(label: 'Ready', color: colors.success)
                            : SWBadge(
                                label: 'Not Ready',
                                color: colors.textMuted,
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // DIAGNOSTICS CARD (COLLAPSIBLE FOR DEBUGGING ONLY)
            SWGlassCard(
              child: ExpansionTile(
                title: Text(
                  'Diagnostics & Jitter',
                  style: typography.body.copyWith(fontWeight: FontWeight.bold),
                ),
                childrenPadding: EdgeInsets.all(spacing.sm.r),
                children: [
                  _buildDiagRow(
                    context,
                    'Avg Latency',
                    '${session.diagnostics.averageLatency.toStringAsFixed(1)} ms',
                  ),
                  _buildDiagRow(
                    context,
                    'Last Seq Received',
                    session.diagnostics.lastSequenceReceived.toString(),
                  ),
                  _buildDiagRow(
                    context,
                    'Last Snap Version',
                    session.diagnostics.lastSnapshotVersion.toString(),
                  ),
                  _buildDiagRow(
                    context,
                    'Sync Health State',
                    session.synchronizationState.name.toUpperCase(),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.xl),

            // BUTTON CONTROLS
            Row(
              children: [
                Expanded(
                  child: SWButton(
                    text: 'Leave Room',
                    onPressed: () => notifier.controller.leaveRoom(),
                    variant: SWButtonVariant.secondary,
                  ),
                ),
                SizedBox(width: spacing.md),
                if (!isHost)
                  Expanded(
                    child: SWButton(
                      text: isLocalReady ? 'Cancel Ready' : 'Ready up',
                      onPressed: () =>
                          notifier.controller.toggleReady(!isLocalReady),
                      variant: SWButtonVariant.primary,
                    ),
                  ),
                if (isHost)
                  Expanded(
                    child: SWButton(
                      text: 'Start Match',
                      onPressed: canStart
                          ? () => notifier.controller.startMatch()
                          : null,
                      variant: SWButtonVariant.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagRow(BuildContext context, String key, String val) {
    final colors = context.swColors;
    final typography = context.swTypography;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: typography.caption.copyWith(color: colors.textMuted),
          ),
          Text(
            val,
            style: typography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

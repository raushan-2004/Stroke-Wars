import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stroke_wars/features/lan/providers/lan_providers.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/multiplayer/application/peer_discovery_service.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class LANBrowserPage extends ConsumerStatefulWidget {
  const LANBrowserPage({super.key});

  @override
  ConsumerState<LANBrowserPage> createState() => _LANBrowserPageState();
}

class _LANBrowserPageState extends ConsumerState<LANBrowserPage> {
  final _roomNameController = TextEditingController(text: 'Sleek LAN Room');
  final _manualIpController = TextEditingController(text: '127.0.0.1');
  final _manualPortController = TextEditingController(text: '18080');

  int _maxPlayers = 4;
  bool _isHosting = false;
  bool _isJoining = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    _manualIpController.dispose();
    _manualPortController.dispose();
    super.dispose();
  }

  Future<void> _handleHost() async {
    setState(() => _isHosting = true);
    final player = ref.read(playerServiceProvider);
    final name = player?.displayName ?? 'Player Host';

    try {
      await ref
          .read(lANSessionStateProvider.notifier)
          .controller
          .hostGame(
            roomName: _roomNameController.text.trim(),
            hostName: name,
            maxPlayers: _maxPlayers,
          );
    } catch (e) {
      if (mounted) {
        SWToast.show(context, 'Hosting failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isHosting = false);
    }
  }

  Future<void> _handleJoin(String ip, int port) async {
    setState(() => _isJoining = true);
    final player = ref.read(playerServiceProvider);
    final name = player?.displayName ?? 'Player Guest';

    try {
      await ref
          .read(lANSessionStateProvider.notifier)
          .controller
          .joinGame(address: ip, port: port, playerName: name);
    } catch (e) {
      if (mounted) {
        SWToast.show(context, 'Joining failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;
    final browserRooms = ref
        .watch(lANSessionStateProvider.notifier)
        .controller
        .discoveredRooms;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'LOCAL MULTIPLAYER',
              textAlign: TextAlign.center,
              style: typography.title.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 26.sp,
                letterSpacing: 2.w,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Play over local Wi-Fi or mobile hotspots',
              textAlign: TextAlign.center,
              style: typography.body.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: spacing.xl),

            // HOST LOBBY CARD
            SWGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Host a LAN Room', style: typography.heading),
                  SizedBox(height: spacing.md),
                  TextField(
                    controller: _roomNameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Max Players', style: typography.body),
                      DropdownButton<int>(
                        value: _maxPlayers,
                        dropdownColor: colors.surfaceContainer,
                        style: typography.body.copyWith(
                          color: colors.textPrimary,
                        ),
                        items: [2, 3, 4, 6, 8]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text('$v Players'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _maxPlayers = v);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  SWButton(
                    text: _isHosting ? 'Starting...' : 'Host Game',
                    onPressed: _isHosting || _isJoining ? null : _handleHost,
                    variant: SWButtonVariant.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // DISCOVERED LOBBIES LIST
            SWGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Discovered LAN Rooms', style: typography.heading),
                  SizedBox(height: spacing.md),
                  StreamBuilder<List<DiscoveredRoom>>(
                    stream: browserRooms,
                    builder: (context, snapshot) {
                      final rooms = snapshot.data ?? [];
                      if (rooms.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: spacing.lg.r),
                          child: Column(
                            children: [
                              const SWCircularLoading(),
                              SizedBox(height: spacing.sm),
                              Text(
                                'Scanning local network...',
                                style: typography.body.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rooms.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: spacing.sm),
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return Container(
                            padding: EdgeInsets.all(spacing.md.r),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      room.roomId.value,
                                      style: typography.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Host: ${room.hostName} • ${room.playerCount}/${room.maxPlayers}',
                                      style: typography.caption.copyWith(
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                SWButton(
                                  text: 'Join',
                                  onPressed: _isHosting || _isJoining
                                      ? null
                                      : () => _handleJoin(
                                          room.address,
                                          room.port,
                                        ),
                                  variant: SWButtonVariant.secondary,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),

            // MANUAL CONNECT CARD
            SWGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Manual Connection', style: typography.heading),
                  SizedBox(height: spacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _manualIpController,
                          decoration: InputDecoration(
                            labelText: 'IP Address',
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: spacing.sm),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _manualPortController,
                          decoration: InputDecoration(
                            labelText: 'Port',
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  SWButton(
                    text: _isJoining ? 'Connecting...' : 'Connect to Host IP',
                    onPressed: _isHosting || _isJoining
                        ? null
                        : () {
                            final ip = _manualIpController.text.trim();
                            final port =
                                int.tryParse(
                                  _manualPortController.text.trim(),
                                ) ??
                                18080;
                            _handleJoin(ip, port);
                          },
                    variant: SWButtonVariant.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/online/providers/online_providers.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';
import 'package:stroke_wars/features/online/application/online_session_controller.dart';
import 'package:stroke_wars/features/online_gameplay/presentation/online_game_page.dart';
import 'package:stroke_wars/features/online/application/lobby_service.dart';
import 'package:stroke_wars/features/profile/application/player_service.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class OnlineSessionPage extends ConsumerStatefulWidget {
  const OnlineSessionPage({super.key});

  @override
  ConsumerState<OnlineSessionPage> createState() => _OnlineSessionPageState();
}

class _OnlineSessionPageState extends ConsumerState<OnlineSessionPage> {
  final _addressController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '18080');
  final _lobbyNameController = TextEditingController(text: 'New Battle Arena');
  final _joinLobbyIdController = TextEditingController();

  int _maxPlayers = 4;
  bool _isConnecting = false;
  bool _isActionInProgress = false;

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _lobbyNameController.dispose();
    _joinLobbyIdController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect(OnlineSessionController controller) async {
    setState(() => _isConnecting = true);
    final player = ref.read(playerServiceProvider);
    final name = player?.displayName ?? 'Player Guest';

    try {
      await controller.connect(
        address: _addressController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 18080,
        playerName: name,
      );
    } catch (e) {
      if (mounted) {
        SWToast.show(context, 'Connection failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _handleCreateLobby(OnlineSessionController controller) async {
    setState(() => _isActionInProgress = true);
    try {
      await controller.createLobby(
        roomName: _lobbyNameController.text.trim(),
        maxPlayers: _maxPlayers,
        isPrivate: false,
      );
    } catch (e) {
      if (mounted) {
        SWToast.show(context, 'Lobby creation failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleJoinLobby(
    OnlineSessionController controller,
    String lobbyId,
  ) async {
    setState(() => _isActionInProgress = true);
    try {
      await controller.joinLobby(lobbyId);
    } catch (e) {
      if (mounted) {
        SWToast.show(context, 'Join lobby failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(onlineSessionStateNotifierProvider);
    final notifier = ref.watch(onlineSessionStateNotifierProvider.notifier);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    Widget body;
    bool showBackButton = false;

    switch (session.sessionState) {
      case OnlineSessionState.disconnected:
      case OnlineSessionState.closed:
        showBackButton = true;
        body = _buildDisconnectedView(context, notifier.controller);
        break;
      case OnlineSessionState.connecting:
        body = _buildConnectingView(context);
        break;
      case OnlineSessionState.connected:
      case OnlineSessionState.browsing:
        body = _buildLobbyBrowserView(context, session, notifier.controller);
        break;
      case OnlineSessionState.lobby:
        body = _buildLobbyView(context, session, notifier.controller);
        break;
      case OnlineSessionState.waiting:
        body = _buildWaitingView(context);
        break;
      case OnlineSessionState.gameplay:
        body = const OnlineGamePage();
        break;
    }

    return AppScaffold(
      useSafeArea: true,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  notifier.controller.disconnect();
                  context.pop();
                },
              ),
              title: Text(
                'Internet Multiplayer',
                style: typography.body.copyWith(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Background Glow
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
          Positioned.fill(child: body),
        ],
      ),
    );
  }

  // DISCONNECTED VIEW
  Widget _buildDisconnectedView(
    BuildContext context,
    OnlineSessionController controller,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ONLINE MULTIPLAYER',
              textAlign: TextAlign.center,
              style: typography.title.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 26.sp,
                letterSpacing: 2.w,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Compete with drawing champions across the globe',
              textAlign: TextAlign.center,
              style: typography.body.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: spacing.xl),

            SWGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Connect to Game Server', style: typography.heading),
                  SizedBox(height: spacing.md),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Server Host / IP',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Server Port',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.lg),
                  SWButton(
                    text: _isConnecting ? 'Connecting...' : 'Connect Server',
                    onPressed: _isConnecting
                        ? null
                        : () => _handleConnect(controller),
                    variant: SWButtonVariant.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONNECTING VIEW
  Widget _buildConnectingView(BuildContext context) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SWCircularLoading(),
          SizedBox(height: spacing.md),
          Text(
            'Negotiating capabilities and authenticating...',
            style: typography.body.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  // LOBBY BROWSER VIEW
  Widget _buildLobbyBrowserView(
    BuildContext context,
    OnlineSession session,
    OnlineSessionController controller,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.lg.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LOBBY BROWSER',
            textAlign: TextAlign.center,
            style: typography.title.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 22.sp,
            ),
          ),
          SizedBox(height: spacing.sm),
          Text(
            'Region: ${session.serverCapabilities?.region ?? 'Auto'} • Protocol v${session.serverCapabilities?.protocolVersion ?? 1}',
            textAlign: TextAlign.center,
            style: typography.caption.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: spacing.lg),

          // CREATE LOBBY CARD
          SWGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create an Online Arena', style: typography.heading),
                SizedBox(height: spacing.md),
                TextField(
                  controller: _lobbyNameController,
                  decoration: InputDecoration(
                    labelText: 'Arena Name',
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
                      items: [2, 4, 6, 8]
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
                  text: _isActionInProgress ? 'Creating...' : 'Create Arena',
                  onPressed: _isActionInProgress
                      ? null
                      : () => _handleCreateLobby(controller),
                  variant: SWButtonVariant.primary,
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.lg),

          // MANUAL JOIN CARD
          SWGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Join Arena Code', style: typography.heading),
                SizedBox(height: spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _joinLobbyIdController,
                        decoration: InputDecoration(
                          labelText: 'Enter Lobby ID / Code',
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    SWButton(
                      text: 'Join',
                      onPressed: _isActionInProgress
                          ? null
                          : () {
                              final id = _joinLobbyIdController.text.trim();
                              if (id.isNotEmpty)
                                _handleJoinLobby(controller, id);
                            },
                      variant: SWButtonVariant.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.lg),

          // BACK BUTTON
          SWButton(
            text: 'Disconnect',
            onPressed: () => controller.disconnect(),
            variant: SWButtonVariant.outlined,
          ),
        ],
      ),
    );
  }

  // LOBBY VIEW
  Widget _buildLobbyView(
    BuildContext context,
    OnlineSession session,
    OnlineSessionController controller,
  ) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    final lobby = session.lobby!;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lobby.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: typography.title.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 24.sp,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Lobby ID: ${lobby.id}',
              textAlign: TextAlign.center,
              style: typography.caption.copyWith(color: colors.textMuted),
            ),
            SizedBox(height: spacing.xl),

            SWGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Players', style: typography.heading),
                      Text('${lobby.players.length}/${lobby.maxPlayers}'),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lobby.players.length,
                    separatorBuilder: (_, __) => Divider(color: colors.border),
                    itemBuilder: (context, index) {
                      final conn = lobby.players[index];
                      final isLobbyHost =
                          conn.peerInfo.id.value == lobby.hostId;
                      return ListTile(
                        leading: SWAvatar(
                          name: conn.peerInfo.displayName,
                          backgroundColor: isLobbyHost
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
                            if (isLobbyHost) ...[
                              SizedBox(width: spacing.xs),
                              SWBadge(label: 'Host', color: colors.primary),
                            ],
                          ],
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
            SizedBox(height: spacing.xl),

            SWButton(
              text: 'Exit Lobby',
              onPressed: () => controller.leaveLobby(),
              variant: SWButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  // WAITING VIEW
  Widget _buildWaitingView(BuildContext context) {
    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SWCircularLoading(),
          SizedBox(height: spacing.md),
          Text(
            'Preparing online match engine arena...',
            style: typography.body.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

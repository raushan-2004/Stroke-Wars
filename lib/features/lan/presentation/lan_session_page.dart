import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:stroke_wars/core/widgets/app_scaffold.dart';
import 'package:stroke_wars/features/lan/providers/lan_providers.dart';
import 'package:stroke_wars/features/lan/domain/models/lan_session_models.dart';
import 'package:stroke_wars/features/lan/presentation/widgets/lan_browser_page.dart';
import 'package:stroke_wars/features/lan/presentation/widgets/lan_lobby_page.dart';
import 'package:stroke_wars/features/lan/presentation/widgets/lan_game_page.dart';
import 'package:stroke_wars/features/lan/presentation/widgets/lan_results_page.dart';
import 'package:stroke_wars/shared/design_language/swdl.dart';

class LANSessionPage extends ConsumerWidget {
  const LANSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(lANSessionStateProvider);
    final notifier = ref.watch(lANSessionStateProvider.notifier);

    final colors = context.swColors;
    final spacing = context.swSpacing;
    final typography = context.swTypography;

    Widget body;
    bool showBackButton = false;

    switch (session.sessionState) {
      case LANSessionLifecycleState.discovering:
      case LANSessionLifecycleState.closed:
        body = const LANBrowserPage();
        showBackButton = true;
        break;
      case LANSessionLifecycleState.joining:
        body = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SWCircularLoading(),
              SizedBox(height: spacing.md),
              Text(
                'Connecting to LAN session...',
                style: typography.body.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        );
        break;
      case LANSessionLifecycleState.lobby:
      case LANSessionLifecycleState.loading:
        body = const LANLobbyPage();
        break;
      case LANSessionLifecycleState.playing:
        // Render gameplay directly
        return const LANGamePage();
      case LANSessionLifecycleState.results:
        body = const LANResultsPage();
        break;
      case LANSessionLifecycleState.disconnected:
        body = Center(
          child: Padding(
            padding: EdgeInsets.all(spacing.lg.r),
            child: SWGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connection Interrupted',
                    textAlign: TextAlign.center,
                    style: typography.heading,
                  ),
                  SizedBox(height: spacing.md),
                  Text(
                    'The connection to the LAN session was lost. Attempting to recover or exit.',
                    textAlign: TextAlign.center,
                    style: typography.body.copyWith(color: colors.textMuted),
                  ),
                  SizedBox(height: spacing.lg),
                  SWButton(
                    text: 'Exit to Menu',
                    onPressed: () => notifier.controller.leaveRoom(),
                    variant: SWButtonVariant.primary,
                  ),
                ],
              ),
            ),
          ),
        );
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
                  notifier.controller.leaveRoom();
                  context.pop();
                },
              ),
              title: Text(
                'LAN Battle',
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:stroke_wars/core/network/connectivity_service.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_icons.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_spacing.dart';
import 'package:stroke_wars/shared/design_language/tokens/sw_theme_extension.dart';

/// A reactive connectivity banner that slides in when offline.
class SWNetworkStatus extends ConsumerWidget {
  /// Creates an [SWNetworkStatus].
  const SWNetworkStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStreamProvider);
    final colors = context.swColors;
    final typography = context.swTypography;

    return connectivity.when(
      data: (state) {
        if (state == ConnectivityState.none) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: SWSpacing.sm),
            color: colors.danger,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SWIcon(SWIcons.error, color: colors.onPrimary, size: 16.r),
                SizedBox(width: SWSpacing.sm),
                Flexible(
                  child: Text(
                    'YOU ARE OFFLINE — Check your connection',
                    style: typography.gameLabel.copyWith(
                      color: colors.onPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

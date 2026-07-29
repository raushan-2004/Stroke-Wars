import 'package:flutter/material.dart';

import 'package:stroke_wars/shared/design_language/swdl.dart';

/// Reusable layout block for dashboard feeds, challenges, and news updates.
class SWDashboardSection extends StatelessWidget {
  /// Creates an [SWDashboardSection] widget.
  const SWDashboardSection({
    required this.title,
    required this.content,
    super.key,
    this.actionLabel,
    this.onActionPressed,
    this.isLoading = false,
    this.isEmpty = false,
    this.emptyMessage = 'No active entries available.',
  });

  /// Section visual title.
  final String title;

  /// Optional action button display label.
  final String? actionLabel;

  /// Optional action trigger callback.
  final VoidCallback? onActionPressed;

  /// Shows shimmer loading skeleton.
  final bool isLoading;

  /// Shows empty message view.
  final bool isEmpty;

  /// Custom empty description.
  final String emptyMessage;

  /// Direct children content.
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final spacing = context.swSpacing;

    Widget resolvedContent = content;

    if (isLoading) {
      resolvedContent = Column(
        children: [
          const SWSkeleton(width: double.infinity, height: 60),
          SizedBox(height: spacing.sm),
          const SWSkeleton(width: double.infinity, height: 60),
        ],
      );
    } else if (isEmpty) {
      resolvedContent = SWEmptyState(
        title: 'Empty Section',
        message: emptyMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SWSectionHeader(
          title: title,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
        ),
        SizedBox(height: spacing.sm),
        resolvedContent,
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'package:stroke_wars/core/constants/spacing_constants.dart';

/// A reusable scaffold that wraps pages with consistent padding and safe area.
///
/// Use this instead of raw [Scaffold] for all feature pages to guarantee
/// uniform layout behaviour.
class AppScaffold extends StatelessWidget {
  /// Creates an [AppScaffold].
  const AppScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.padding,
    this.useSafeArea = true,
  });

  /// The primary content of the scaffold.
  final Widget body;

  /// An app bar to display at the top of the scaffold.
  final PreferredSizeWidget? appBar;

  /// A navigation bar to display at the bottom of the scaffold.
  final Widget? bottomNavigationBar;

  /// A floating action button.
  final Widget? floatingActionButton;

  /// The color to paint the background.
  final Color? backgroundColor;

  /// Whether the body should size itself to avoid the window insets.
  final bool resizeToAvoidBottomInset;

  /// Padding around the body.
  final EdgeInsetsGeometry? padding;

  /// Whether to wrap the body in a [SafeArea].
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.pagePaddingH);

    Widget content = Padding(padding: effectivePadding, child: body);

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: content,
    );
  }
}

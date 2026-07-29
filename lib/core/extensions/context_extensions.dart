import 'package:flutter/material.dart';

/// Extension methods on [BuildContext] for convenient access to theme data.
extension ContextThemeExtension on BuildContext {
  /// Returns the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Returns the current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Returns the current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Returns true if the current theme is dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Returns the current [Brightness].
  Brightness get brightness => Theme.of(this).brightness;

  /// Returns the [MediaQueryData] for the current context.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Returns the screen width.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns the screen height.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Returns the device pixel ratio.
  double get pixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Returns true if the device is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// Returns the bottom padding (keyboard/system navigation inset).
  double get bottomInset => MediaQuery.of(this).viewInsets.bottom;
}

/// Extension methods on [BuildContext] for navigation.
extension ContextNavigationExtension on BuildContext {
  /// Returns the [FocusScopeNode] for unfocusing.
  void unfocus() => FocusScope.of(this).unfocus();
}

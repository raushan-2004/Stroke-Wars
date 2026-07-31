/// Accessible option preferences.
class AccessibilitySettings {
  final bool reducedMotion;
  final bool highContrast;
  final bool largeText;
  final double dynamicTextScale;
  final String
  colorBlindPalette; // 'none', 'protanopia', 'deuteranopia', 'tritanopia'
  final bool hapticsEnabled;
  final bool keyboardNavigation;

  const AccessibilitySettings({
    required this.reducedMotion,
    required this.highContrast,
    required this.largeText,
    required this.dynamicTextScale,
    required this.colorBlindPalette,
    required this.hapticsEnabled,
    required this.keyboardNavigation,
  });

  AccessibilitySettings copyWith({
    bool? reducedMotion,
    bool? highContrast,
    bool? largeText,
    double? dynamicTextScale,
    String? colorBlindPalette,
    bool? hapticsEnabled,
    bool? keyboardNavigation,
  }) {
    return AccessibilitySettings(
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
      largeText: largeText ?? this.largeText,
      dynamicTextScale: dynamicTextScale ?? this.dynamicTextScale,
      colorBlindPalette: colorBlindPalette ?? this.colorBlindPalette,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      keyboardNavigation: keyboardNavigation ?? this.keyboardNavigation,
    );
  }
}

/// Centralized manager tracking haptic, text scale, and colorblind preferences.
class AccessibilityManager {
  AccessibilitySettings _settings = const AccessibilitySettings(
    reducedMotion: false,
    highContrast: false,
    largeText: false,
    dynamicTextScale: 1.0,
    colorBlindPalette: 'none',
    hapticsEnabled: true,
    keyboardNavigation: false,
  );

  AccessibilitySettings get settings => _settings;

  /// Updates settings dynamically.
  void updateSettings(AccessibilitySettings next) {
    _settings = next;
  }

  /// Helper verifying touch target size compliance (minimum 48x48 logical pixels).
  bool verifyTouchTargetSize(double width, double height) {
    return width >= 48.0 && height >= 48.0;
  }

  /// Verifies color contrast ratio compliance (WCAG AA requires 4.5:1, AAA requires 7:1).
  bool verifyContrastCompliance(double ratio) {
    return ratio >= 4.5;
  }
}

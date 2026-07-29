/// String extension methods used throughout Stroke Wars.
extension StringExtension on String {
  /// Returns the string with the first character capitalized.
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns the string with each word capitalized.
  String get titleCase {
    return split(' ').map((word) => word.capitalizeFirst).join(' ');
  }

  /// Returns true if this string is a valid non-empty value.
  bool get isNotBlank => trim().isNotEmpty;

  /// Returns true if this string is blank (empty or whitespace only).
  bool get isBlank => trim().isEmpty;

  /// Truncates the string to [maxLength] characters, appending [ellipsis].
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Returns null if the string is blank, otherwise returns itself.
  String? get nullIfBlank => isBlank ? null : this;
}

/// Nullable string extension methods.
extension NullableStringExtension on String? {
  /// Returns true if the string is null or blank.
  bool get isNullOrBlank => this == null || this!.isBlank;

  /// Returns the string or a fallback value if null/blank.
  String orElse(String fallback) {
    return isNullOrBlank ? fallback : this!;
  }
}

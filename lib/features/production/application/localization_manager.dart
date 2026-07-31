/// Simple adapter resolving localized text strings, date masks, and plurals.
class LocalizationManager {
  String _currentLocale = 'en';

  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'app_title': 'Stroke Wars',
      'lobby_title': 'LAN Lobby',
      'shop_unlock': 'Unlock Skin',
      'one_player': '1 Player',
      'many_players': '{} Players',
    },
    'es': {
      'app_title': 'Guerra de Trazos',
      'lobby_title': 'Sala LAN',
      'shop_unlock': 'Desbloquear Aspecto',
      'one_player': '1 Jugador',
      'many_players': '{} Jugadores',
    }
  };

  String get currentLocale => _currentLocale;

  /// Updates current active language pack.
  void switchLocale(String locale) {
    if (_localizedStrings.containsKey(locale)) {
      _currentLocale = locale;
    }
  }

  /// Translates key string, falling back to English if missing.
  String translate(String key) {
    final localized = _localizedStrings[_currentLocale]?[key];
    if (localized != null) return localized;
    // Fallback locale behavior
    return _localizedStrings['en']?[key] ?? key;
  }

  /// Evaluates plural formats.
  String translatePlural(String key, int count) {
    if (count == 1) {
      return translate('one_player');
    }
    final raw = translate(key);
    return raw.replaceAll('{}', count.toString());
  }

  /// Formats date strings based on active locale.
  String formatDate(DateTime date) {
    if (_currentLocale == 'es') {
      return '${date.day}/${date.month}/${date.year}';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Formats currency balances.
  String formatNumber(double value) {
    if (_currentLocale == 'es') {
      return value.toStringAsFixed(2).replaceAll('.', ',');
    }
    return value.toStringAsFixed(2);
  }

  /// Returns true if language script uses right-to-left layout.
  bool isRtl(String locale) {
    return locale == 'ar' || locale == 'he';
  }
}

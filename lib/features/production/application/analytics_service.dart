import 'package:stroke_wars/features/production/domain/models/production_models.dart';

/// Abstract contract for recording business and feature tracking metrics.
abstract interface class AnalyticsService {
  List<AnalyticsEvent> get events;
  void trackEvent(String name, [Map<String, dynamic>? parameters]);
}

/// Simulated locally stateful Analytics service.
class MockAnalyticsService implements AnalyticsService {
  final List<AnalyticsEvent> _events = [];

  @override
  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  @override
  void trackEvent(String name, [Map<String, dynamic>? parameters]) {
    _events.add(AnalyticsEvent(
      name: name,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
    ));
  }
}

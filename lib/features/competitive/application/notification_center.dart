import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';

/// Passive local notifications publisher buffering system alerts.
class NotificationCenter {
  final List<SWNotification> _notifications = [];
  final List<void Function(List<SWNotification>)> _listeners = [];

  List<SWNotification> get notifications => List.unmodifiable(_notifications);

  void addListener(void Function(List<SWNotification>) listener) {
    _listeners.add(listener);
    listener(notifications);
  }

  void removeListener(void Function(List<SWNotification>) listener) {
    _listeners.remove(listener);
  }

  /// Appends and broadcasts a new notification alert.
  void postNotification({
    required String title,
    required String body,
    required String
    type, // 'friend_request', 'mission_reward', 'season_reward', 'shop_unlock'
  }) {
    final notification = SWNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${_notifications.length}',
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
    );

    // Keep chronological order (newest first)
    _notifications.insert(0, notification);
    _notifyListeners();
  }

  /// Clears a single notification by ID.
  void dismissNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  /// Clears all notification history.
  void clearAll() {
    _notifications.clear();
    _notifyListeners();
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener(notifications);
    }
  }
}

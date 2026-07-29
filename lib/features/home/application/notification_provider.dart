import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_provider.g.dart';

/// Lightweight provider returning the current total notification badge count.
@riverpod
int notificationBadgeCount(NotificationBadgeCountRef ref) {
  // Placeholder architecture for Stage 3, to be wired with real services in future stages.
  return 3;
}

/// Lightweight provider returning the current total unread notifications count.
@riverpod
int notificationUnreadCount(NotificationUnreadCountRef ref) {
  // Placeholder architecture for Stage 3, to be wired with real services in future stages.
  return 2;
}

/// Defines the states of a multiplayer connection.
enum NetworkConnectionState {
  disconnected,
  discovering,
  connecting,
  connected,
  reconnecting,
  failed,
  closed,
}

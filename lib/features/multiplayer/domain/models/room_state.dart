/// Represents the status/lifecycle state of the room lobby.
enum RoomState {
  /// Waiting for players to join and get ready.
  waiting,

  /// In the countdown/start phase.
  starting,

  /// Active match is in progress.
  playing,

  /// Match is finished, displaying final rankings.
  finished,

  /// Room has been dismantled.
  closed,
}

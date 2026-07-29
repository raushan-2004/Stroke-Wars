/// The role a player holds within a match.
enum PlayerRole {
  /// Hosts the match and has additional management privileges.
  host,

  /// The active drawing player for the current round.
  drawer,

  /// Attempts to guess the drawn word.
  guesser,

  /// Observes without participating (joined full game, future use).
  spectator,

  /// Reserved for future moderation features.
  moderator,
}

/// Extension providing human-readable labels for [PlayerRole].
extension PlayerRoleLabel on PlayerRole {
  /// Returns the display name for this role.
  String get label => switch (this) {
    PlayerRole.host => 'Host',
    PlayerRole.drawer => 'Drawer',
    PlayerRole.guesser => 'Guesser',
    PlayerRole.spectator => 'Spectator',
    PlayerRole.moderator => 'Moderator',
  };

  /// Returns true if this role can submit guesses.
  bool get canGuess => this == PlayerRole.guesser || this == PlayerRole.host;

  /// Returns true if this role can draw.
  bool get canDraw => this == PlayerRole.drawer;
}

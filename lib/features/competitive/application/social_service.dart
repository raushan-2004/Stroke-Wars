import 'package:stroke_wars/features/competitive/domain/models/competitive_models.dart';

/// Simulates active social graphs, pending friend requests, presence changes, and parties.
class SocialGraphService {
  final List<Friend> _friends = [
    const Friend(
      userId: 'f-1',
      displayName: 'David (PaintLord)',
      presence: 'online',
    ),
    const Friend(
      userId: 'f-2',
      displayName: 'Emily (SketchMaster)',
      presence: 'ingame',
    ),
    const Friend(
      userId: 'f-3',
      displayName: 'Chris (StrokeKing)',
      presence: 'offline',
    ),
  ];

  final List<FriendRequest> _friendRequests = [
    const FriendRequest(fromUserId: 'r-1', fromDisplayName: 'GamerGuy99'),
  ];

  final List<Invite> _invites = [];
  Party? _currentParty;

  List<Friend> get friends => List.unmodifiable(_friends);
  List<FriendRequest> get friendRequests => List.unmodifiable(_friendRequests);
  List<Invite> get invites => List.unmodifiable(_invites);
  Party? get currentParty => _currentParty;

  /// Adds a friend request.
  void sendFriendRequest(String userId, String displayName) {
    if (!_friends.any((f) => f.userId == userId) &&
        !_friendRequests.any((r) => r.fromUserId == userId)) {
      _friendRequests.add(
        FriendRequest(fromUserId: userId, fromDisplayName: displayName),
      );
    }
  }

  /// Accepts a friend request, adding them to friends.
  void acceptFriendRequest(String userId) {
    final reqIndex = _friendRequests.indexWhere((r) => r.fromUserId == userId);
    if (reqIndex != -1) {
      final req = _friendRequests.removeAt(reqIndex);
      _friends.add(
        Friend(
          userId: req.fromUserId,
          displayName: req.fromDisplayName,
          presence: 'online',
        ),
      );
    }
  }

  /// Rejects a friend request.
  void declineFriendRequest(String userId) {
    _friendRequests.removeWhere((r) => r.fromUserId == userId);
  }

  /// Removes a friend from the list.
  void removeFriend(String userId) {
    _friends.removeWhere((f) => f.userId == userId);
  }

  /// Updates a friend's presence status dynamically.
  void updatePresence(String userId, String presence) {
    final index = _friends.indexWhere((f) => f.userId == userId);
    if (index != -1) {
      _friends[index] = _friends[index].copyWith(presence: presence);
    }
  }

  /// Forms an active party lobby.
  void createParty(String hostId) {
    _currentParty = Party(
      partyId: 'party_${DateTime.now().millisecondsSinceEpoch}',
      hostId: hostId,
      members: [hostId],
    );
  }

  /// Invites a friend to join the party.
  void sendPartyInvite(String friendId, String senderName) {
    // Simply record that we sent it, or mock receiving one
    _invites.add(
      Invite(
        partyId: _currentParty?.partyId ?? 'party_123',
        senderName: senderName,
      ),
    );
  }

  /// Accepts a party invite.
  void acceptPartyInvite(String partyId, String memberId) {
    _currentParty = Party(
      partyId: partyId,
      hostId: 'f-1', // Mock host ID
      members: ['f-1', memberId],
    );
    _invites.removeWhere((i) => i.partyId == partyId);
  }

  /// Leaves the active party.
  void leaveParty() {
    _currentParty = null;
  }

  /// Resets social graph states.
  void reset() {
    _friends.clear();
    _friends.addAll([
      const Friend(
        userId: 'f-1',
        displayName: 'David (PaintLord)',
        presence: 'online',
      ),
      const Friend(
        userId: 'f-2',
        displayName: 'Emily (SketchMaster)',
        presence: 'ingame',
      ),
      const Friend(
        userId: 'f-3',
        displayName: 'Chris (StrokeKing)',
        presence: 'offline',
      ),
    ]);
    _friendRequests.clear();
    _friendRequests.add(
      const FriendRequest(fromUserId: 'r-1', fromDisplayName: 'GamerGuy99'),
    );
    _invites.clear();
    _currentParty = null;
  }
}

import 'dart:async';
import 'package:stroke_wars/features/online/application/online_protocol_service.dart';
import 'package:stroke_wars/features/online/data/websocket_transport.dart';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';

/// Lobby metadata payload definition.
class DiscoveredLobby {
  const DiscoveredLobby({
    required this.lobbyId,
    required this.name,
    required this.hostName,
    required this.playerCount,
    required this.maxPlayers,
    required this.isPrivate,
  });

  final String lobbyId;
  final String name;
  final String hostName;
  final int playerCount;
  final int maxPlayers;
  final bool isPrivate;

  Map<String, dynamic> toJson() => {
    'lobbyId': lobbyId,
    'name': name,
    'hostName': hostName,
    'playerCount': playerCount,
    'maxPlayers': maxPlayers,
    'isPrivate': isPrivate,
  };

  factory DiscoveredLobby.fromJson(Map<String, dynamic> json) =>
      DiscoveredLobby(
        lobbyId: json['lobbyId'] as String,
        name: json['name'] as String,
        hostName: json['hostName'] as String,
        playerCount: json['playerCount'] as int? ?? 1,
        maxPlayers: json['maxPlayers'] as int? ?? 8,
        isPrivate: json['isPrivate'] as bool? ?? false,
      );
}

/// Service owning active Lobby list caches, query fires, and lifecycle actions.
class LobbyService {
  LobbyService({required this.transport, required this.protocolService});

  final WebSocketTransport transport;
  final OnlineProtocolService protocolService;

  final _lobbiesStreamController =
      StreamController<List<DiscoveredLobby>>.broadcast();
  List<DiscoveredLobby> _cachedLobbies = [];

  Stream<List<DiscoveredLobby>> get publicLobbies =>
      _lobbiesStreamController.stream;

  /// Triggers a fetch/search of public lobbies.
  Future<void> searchPublicLobbies() async {
    final packet = protocolService.buildJoinLobbyRequest('list_all', null);
    await transport.send('server', packet);
  }

  /// Initiates creation of a lobby on the server.
  Future<void> createLobby({
    required String name,
    required int maxPlayers,
    required bool isPrivate,
    String? privateCode,
  }) async {
    final packet = protocolService.buildCreateLobbyRequest(
      name: name,
      maxPlayers: maxPlayers,
      isPrivate: isPrivate,
      privateCode: privateCode,
    );
    await transport.send('server', packet);
  }

  /// Initiates joining a lobby by identifier or private code.
  Future<void> joinLobby(String lobbyId, [String? privateCode]) async {
    final packet = protocolService.buildJoinLobbyRequest(lobbyId, privateCode);
    await transport.send('server', packet);
  }

  /// Leaves the current lobby on the server.
  Future<void> leaveLobby() async {
    final packet = protocolService.buildLeaveLobbyRequest();
    await transport.send('server', packet);
  }

  /// Updates cache from incoming list events.
  void updateLobbiesList(List<DiscoveredLobby> newList) {
    _cachedLobbies = newList;
    _lobbiesStreamController.add(List.unmodifiable(_cachedLobbies));
  }

  void dispose() {
    _lobbiesStreamController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stroke_wars/core/services/logger_service.dart';
import 'package:stroke_wars/features/multiplayer/domain/models/unique_ids.dart';

/// Represents a validated, active game room found on the local network.
class DiscoveredRoom {
  const DiscoveredRoom({
    required this.roomId,
    required this.hostName,
    required this.address,
    required this.port,
    required this.playerCount,
    required this.maxPlayers,
    required this.protocolVersion,
    required this.engineVersion,
    required this.roomState,
    required this.lastSeen,
  });

  final RoomId roomId;
  final String hostName;
  final String address;
  final int port;
  final int playerCount;
  final int maxPlayers;
  final int protocolVersion;
  final String engineVersion;
  final String roomState;
  final DateTime lastSeen;

  Map<String, dynamic> toJson() => {
    'roomId': roomId.value,
    'hostName': hostName,
    'address': address,
    'port': port,
    'playerCount': playerCount,
    'maxPlayers': maxPlayers,
    'protocolVersion': protocolVersion,
    'engineVersion': engineVersion,
    'roomState': roomState,
  };

  factory DiscoveredRoom.fromJson(String address, Map<String, dynamic> json) =>
      DiscoveredRoom(
        roomId: RoomId(json['roomId'] as String),
        hostName: json['hostName'] as String,
        address: address,
        port: json['port'] as int,
        playerCount: json['playerCount'] as int,
        maxPlayers: json['maxPlayers'] as int? ?? 8,
        protocolVersion: json['protocolVersion'] as int,
        engineVersion: json['engineVersion'] as String,
        roomState: json['roomState'] as String,
        lastSeen: DateTime.now(),
      );
}

/// Transport-independent service handling local UDP network peer discovery and advertisement.
class PeerDiscoveryService {
  PeerDiscoveryService({
    this.discoveryPort = 18081,
    this.protocolVersion = 1,
    this.engineVersion = '1.0.0',
  });

  final int discoveryPort;
  final int protocolVersion;
  final String engineVersion;

  RawDatagramSocket? _advertiseSocket;
  RawDatagramSocket? _browseSocket;
  Timer? _advertiseTimer;
  Timer? _pruneTimer;

  final Map<String, DiscoveredRoom> _discoveredRooms = {};
  final StreamController<List<DiscoveredRoom>> _roomsController =
      StreamController<List<DiscoveredRoom>>.broadcast();

  /// Stream of currently active and compatible rooms discovered on the LAN.
  Stream<List<DiscoveredRoom>> get discoveredRooms => _roomsController.stream;

  /// Returns the current list of discovered rooms snapshot.
  List<DiscoveredRoom> get activeRooms => _discoveredRooms.values.toList();

  /// Starts broadcasting room availability payload periodically over UDP.
  Future<void> startAdvertising({
    required RoomId roomId,
    required String hostName,
    required int playerCount,
    required int maxPlayers,
    required int gamePort,
    required String roomState,
    Duration interval = const Duration(seconds: 2),
  }) async {
    await stopAdvertising();

    try {
      _advertiseSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      _advertiseSocket!.broadcastEnabled = true;

      _advertiseTimer = Timer.periodic(interval, (_) {
        try {
          final payload = {
            'roomId': roomId.value,
            'hostName': hostName,
            'playerCount': playerCount,
            'maxPlayers': maxPlayers,
            'port': gamePort,
            'protocolVersion': protocolVersion,
            'engineVersion': engineVersion,
            'roomState': roomState,
          };
          final data = utf8.encode(jsonEncode(payload));
          _advertiseSocket!.send(
            data,
            InternetAddress('255.255.255.255'),
            discoveryPort,
          );
          _advertiseSocket!.send(
            data,
            InternetAddress.loopbackIPv4,
            discoveryPort,
          );
        } catch (e) {
          AppLogger.instance.error('Error sending discovery broadcast: $e');
        }
      });
      AppLogger.instance.info(
        'UDP advertising started on port: $discoveryPort',
      );
    } catch (e) {
      AppLogger.instance.error('Failed to bind advertising socket: $e');
    }
  }

  /// Stops broadcasting room availability.
  Future<void> stopAdvertising() async {
    _advertiseTimer?.cancel();
    _advertiseTimer = null;
    _advertiseSocket?.close();
    _advertiseSocket = null;
  }

  /// Starts scanning the network for UDP room advertisement packets.
  Future<void> startBrowsing() async {
    await stopBrowsing();
    _discoveredRooms.clear();

    try {
      _browseSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
      );
      _browseSocket!.listen(
        (RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final Datagram? datagram = _browseSocket!.receive();
            if (datagram != null) {
              try {
                final rawString = utf8.decode(datagram.data);
                final json = jsonDecode(rawString) as Map<String, dynamic>;

                final roomProto = json['protocolVersion'] as int;
                final roomEngine = json['engineVersion'] as String;

                // Validate protocol version compatibility
                if (roomProto != protocolVersion ||
                    roomEngine != engineVersion) {
                  // Incompatible version, ignore gracefully
                  return;
                }

                final address = datagram.address.address;
                final room = DiscoveredRoom.fromJson(address, json);

                _discoveredRooms[room.roomId.value] = room;
                _roomsController.add(_discoveredRooms.values.toList());
              } catch (e) {
                AppLogger.instance.error('Error parsing room packet: $e');
              }
            }
          }
        },
        onError: (Object error) {
          AppLogger.instance.error('UDP browse socket error: $error');
        },
      );

      // Periodically prune stale rooms that haven't advertised for 6 seconds
      _pruneTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        final now = DateTime.now();
        final beforeCount = _discoveredRooms.length;
        _discoveredRooms.removeWhere(
          (_, room) => now.difference(room.lastSeen).inSeconds > 6,
        );
        if (_discoveredRooms.length != beforeCount) {
          _roomsController.add(_discoveredRooms.values.toList());
        }
      });
      AppLogger.instance.info('UDP browsing started on port: $discoveryPort');
    } catch (e) {
      AppLogger.instance.error('Failed to bind browse socket: $e');
    }
  }

  /// Stops scanning the network for rooms.
  Future<void> stopBrowsing() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    _browseSocket?.close();
    _browseSocket = null;
  }
}

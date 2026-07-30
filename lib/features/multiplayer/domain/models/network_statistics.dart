/// Dedicated immutable model representing network statistics and health diagnostics.
class NetworkStatistics {
  const NetworkStatistics({
    this.latencyMs = 0.0,
    this.jitterMs = 0.0,
    this.packetsSent = 0,
    this.packetsReceived = 0,
    this.packetsDropped = 0,
    this.reconnectCount = 0,
    this.heartbeatFailures = 0,
  });

  /// Current round-trip latency in milliseconds.
  final double latencyMs;

  /// Variance in latency over time in milliseconds.
  final double jitterMs;

  /// Total count of envelopes/packets successfully sent.
  final int packetsSent;

  /// Total count of envelopes/packets successfully received.
  final int packetsReceived;

  /// Total count of lost/dropped packets detected.
  final int packetsDropped;

  /// Total count of reconnect attempts executed during the session.
  final int reconnectCount;

  /// Total count of consecutive heartbeat failure events occurred.
  final int heartbeatFailures;

  /// Helper to copy statistics with updated values.
  NetworkStatistics copyWith({
    double? latencyMs,
    double? jitterMs,
    int? packetsSent,
    int? packetsReceived,
    int? packetsDropped,
    int? reconnectCount,
    int? heartbeatFailures,
  }) {
    return NetworkStatistics(
      latencyMs: latencyMs ?? this.latencyMs,
      jitterMs: jitterMs ?? this.jitterMs,
      packetsSent: packetsSent ?? this.packetsSent,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      packetsDropped: packetsDropped ?? this.packetsDropped,
      reconnectCount: reconnectCount ?? this.reconnectCount,
      heartbeatFailures: heartbeatFailures ?? this.heartbeatFailures,
    );
  }

  /// Converts this instance to a JSON map.
  Map<String, dynamic> toJson() => {
    'latencyMs': latencyMs,
    'jitterMs': jitterMs,
    'packetsSent': packetsSent,
    'packetsReceived': packetsReceived,
    'packetsDropped': packetsDropped,
    'reconnectCount': reconnectCount,
    'heartbeatFailures': heartbeatFailures,
  };

  /// Restores this instance from a JSON map.
  factory NetworkStatistics.fromJson(Map<String, dynamic> json) =>
      NetworkStatistics(
        latencyMs: (json['latencyMs'] as num?)?.toDouble() ?? 0.0,
        jitterMs: (json['jitterMs'] as num?)?.toDouble() ?? 0.0,
        packetsSent: json['packetsSent'] as int? ?? 0,
        packetsReceived: json['packetsReceived'] as int? ?? 0,
        packetsDropped: json['packetsDropped'] as int? ?? 0,
        reconnectCount: json['reconnectCount'] as int? ?? 0,
        heartbeatFailures: json['heartbeatFailures'] as int? ?? 0,
      );
}

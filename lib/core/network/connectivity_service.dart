import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:stroke_wars/core/services/logger_service.dart';

part 'connectivity_service.g.dart';

/// Represents the current network connectivity state.
enum ConnectivityState {
  /// Device has an active Wi-Fi connection.
  wifi,

  /// Device has an active mobile data connection.
  mobile,

  /// Device is connected via ethernet.
  ethernet,

  /// Device is connected via Bluetooth.
  bluetooth,

  /// Device is using a VPN connection.
  vpn,

  /// No network connectivity detected.
  none,
}

/// Reactive connectivity service backed by connectivity_plus.
///
/// Exposes the current [ConnectivityState] as a Riverpod stream provider.
/// Automatically disposes the subscription when no longer needed.
final class ConnectivityService {
  /// Creates a [ConnectivityService].
  ConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  /// Returns a stream of [ConnectivityState] that emits whenever
  /// the network status changes.
  Stream<ConnectivityState> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_mapResults);
  }

  /// Returns the current [ConnectivityState] as a one-time snapshot.
  Future<ConnectivityState> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  /// Returns true if any network connection is active.
  Future<bool> get isConnected async {
    final state = await checkConnectivity();
    return state != ConnectivityState.none;
  }

  ConnectivityState _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityState.wifi;
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityState.ethernet;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityState.mobile;
    }
    if (results.contains(ConnectivityResult.bluetooth)) {
      return ConnectivityState.bluetooth;
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return ConnectivityState.vpn;
    }
    return ConnectivityState.none;
  }
}

/// Provider for the [ConnectivityService].
@riverpod
ConnectivityService connectivityService(ConnectivityServiceRef ref) {
  return ConnectivityService();
}

/// Reactive stream provider for the current [ConnectivityState].
@riverpod
Stream<ConnectivityState> connectivityStream(ConnectivityStreamRef ref) {
  final service = ref.watch(connectivityServiceProvider);
  AppLogger.instance.debug('Connectivity stream initialized');
  return service.onConnectivityChanged;
}

/// Async provider that returns the current [ConnectivityState] snapshot.
@riverpod
Future<ConnectivityState> currentConnectivity(CurrentConnectivityRef ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.checkConnectivity();
}

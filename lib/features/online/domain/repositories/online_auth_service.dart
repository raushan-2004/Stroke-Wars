import 'dart:async';
import 'package:stroke_wars/features/online/domain/models/online_session_models.dart';

/// Representation of an authenticated user session.
class GuestIdentity {
  const GuestIdentity({
    required this.token,
    required this.playerId,
    required this.displayName,
  });

  final String token;
  final String playerId;
  final String displayName;
}

/// Abstract contract managing online authentication methods.
abstract class OnlineAuthService {
  /// Stream emitting changes in authentication state.
  Stream<AuthenticationState> get authState;

  /// Current authentication state getter.
  AuthenticationState get currentAuthState;

  /// Executes anonymous guest login.
  Future<GuestIdentity> loginAnonymously(String name);

  /// Future JWT validation hook.
  Future<GuestIdentity> loginWithToken(String jwtToken);

  /// Clears credentials and logs out.
  Future<void> logout();
}

/// In-memory mock authentication service implementation.
class MockOnlineAuthService implements OnlineAuthService {
  final _stateController = StreamController<AuthenticationState>.broadcast();
  AuthenticationState _state = AuthenticationState.unauthenticated;

  @override
  Stream<AuthenticationState> get authState => _stateController.stream;

  @override
  AuthenticationState get currentAuthState => _state;

  @override
  Future<GuestIdentity> loginAnonymously(String name) async {
    _updateState(AuthenticationState.authenticating);
    await Future.delayed(const Duration(milliseconds: 300));

    if (name.trim().isEmpty) {
      _updateState(AuthenticationState.authenticationFailed);
      throw ArgumentError('Display name cannot be empty');
    }

    final identity = GuestIdentity(
      token: 'mock-jwt-guest-token-${DateTime.now().millisecondsSinceEpoch}',
      playerId: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      displayName: name,
    );

    _updateState(AuthenticationState.authenticated);
    return identity;
  }

  @override
  Future<GuestIdentity> loginWithToken(String jwtToken) async {
    _updateState(AuthenticationState.authenticating);
    await Future.delayed(const Duration(milliseconds: 300));

    if (jwtToken.contains('invalid')) {
      _updateState(AuthenticationState.authenticationFailed);
      throw ArgumentError('Invalid JWT token provided');
    }

    final identity = GuestIdentity(
      token: jwtToken,
      playerId: 'user-jwt-123',
      displayName: 'Verified JWT User',
    );

    _updateState(AuthenticationState.authenticated);
    return identity;
  }

  @override
  Future<void> logout() async {
    _updateState(AuthenticationState.unauthenticated);
  }

  void _updateState(AuthenticationState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
  }
}

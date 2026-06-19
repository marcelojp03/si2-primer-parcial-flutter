import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:si2_p1_mobile/core/api/api_exceptions.dart';
import 'package:si2_p1_mobile/core/models/user_model.dart';
import 'package:si2_p1_mobile/core/services/auth_service.dart';
import 'package:si2_p1_mobile/core/services/ws_service.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: errorMessage,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasToken = await _service.hasToken();
    if (hasToken) {
      try {
        final user = await _service.getProfile();
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        await _connectWebSocket();
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await _clearSession();
          return;
        }
        state = state.copyWith(status: AuthStatus.notAuthenticated);
      } catch (_) {
        await _clearSession();
      }
    } else {
      state = state.copyWith(status: AuthStatus.notAuthenticated);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.checking, errorMessage: null);
    try {
      final user = await _service.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      await _connectWebSocket();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.notAuthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String ci,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.checking, errorMessage: null);
    try {
      final user = await _service.register(
        fullName: fullName,
        ci: ci,
        email: email,
        password: password,
        phone: phone,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      await _connectWebSocket();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.notAuthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _clearSession();
  }

  Future<void> _connectWebSocket() async {
    final ws = WsService();
    ws.reset();
    await ws.connect();
  }

  void _disconnectWebSocket() {
    WsService().close();
  }

  Future<void> _clearSession() async {
    _disconnectWebSocket();
    await _service.logout();
    state = const AuthState(status: AuthStatus.notAuthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(AuthService()),
);

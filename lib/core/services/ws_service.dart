import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:si2_p1_mobile/config/env.dart';
import 'package:si2_p1_mobile/core/storage/secure_storage_service.dart';

/// Servicio WebSocket singleton con reconexión exponencial y heartbeat.
/// Envelope: {type, version, payload, ts}
class WsService {
  static final WsService _instance = WsService._internal();
  factory WsService() => _instance;
  WsService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  bool _connecting = false;
  bool _isConnected = false;
  bool _authFailure = false;
  int? _activeIncidentId;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream de todos los mensajes WS recibidos.
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  /// Filtra mensajes por tipo de evento.
  Stream<Map<String, dynamic>> on(String type) =>
      messages.where((m) => m['type'] == type);

  /// Conecta al WS usando el JWT guardado en SecureStorage.
  Future<void> connect() async {
    if (_disposed) return;
    if (_connecting || _isConnected) return;
    if (_authFailure) return;

    final token = await SecureStorageService().getToken();
    if (token == null || token.isEmpty) return;

    // Derivar WS URL desde la base URL HTTP
    final baseUrl = Env.baseUrl; // e.g. https://host/api/v1
    final wsBase = baseUrl
        .replaceFirst('/api/v1', '')
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$wsBase/ws?token=$token');

    developer.log(
      '🔌 WS connecting: ${_redactSensitive(uri.toString())}',
      name: 'WsService',
    );
    _connecting = true;
    try {
      _channel = WebSocketChannel.connect(uri);
      _sub = _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _markConnected();
            // Responder a ping del servidor
            if (msg['type'] == 'ping') {
              send({'type': 'pong'});
              return;
            }
            developer.log('📨 WS recv: ${msg["type"]}', name: 'WsService');
            if (!_controller.isClosed) _controller.add(msg);
          } catch (_) {}
        },
        onError: (error) => _handleSocketError(error),
        onDone: _handleSocketDone,
        cancelOnError: false,
      );

      await _channel!.ready.timeout(const Duration(seconds: 10));
      if (_disposed) return;
      _markConnected();
    } catch (e) {
      _handleConnectFailure(e);
    } finally {
      _connecting = false;
    }
  }

  /// Envía un mensaje JSON al servidor.
  void send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  void subscribeIncident(int incidentId) {
    _activeIncidentId = incidentId;
    if (_isConnected) {
      _sendSubscribeIncident(incidentId);
    } else {
      developer.log(
        '📡 WS subscribe pending incident:$incidentId',
        name: 'WsService',
      );
    }
  }

  void unsubscribeIncident(int incidentId) {
    if (_activeIncidentId == incidentId) {
      _activeIncidentId = null;
    }
    if (_isConnected) {
      send({'type': 'unsubscribe_incident', 'incident_id': incidentId});
    }
    developer.log('📴 WS unsubscribe incident:$incidentId', name: 'WsService');
  }

  /// Cierra la conexión definitivamente (al hacer logout).
  void close() {
    _disposed = true;
    _connecting = false;
    _authFailure = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _activeIncidentId = null;
  }

  /// Reinicia para una nueva sesión (al hacer login de nuevo).
  void reset() {
    _disposed = false;
    _connecting = false;
    _authFailure = false;
    _reconnectAttempts = 0;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send({'type': 'ping'});
    });
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    if (_authFailure) return;
    _heartbeatTimer?.cancel();
    _sub?.cancel();
    _channel = null;
    _isConnected = false;

    final delay = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;
    developer.log(
      '⏱ WS reconnect in ${delay}s (attempt $_reconnectAttempts)',
      name: 'WsService',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }

  void _markConnected() {
    if (_isConnected) return;
    _isConnected = true;
    _authFailure = false;
    _reconnectAttempts = 0;
    _startHeartbeat();
    _resubscribeActiveIncident();
  }

  void _handleConnectFailure(Object error) {
    _heartbeatTimer?.cancel();
    _sub?.cancel();
    _channel = null;
    _isConnected = false;

    final message = _redactSensitive('$error');
    if (_looksLikeAuthFailure(error)) {
      _authFailure = true;
      developer.log(
        '🔒 WS auth failed; reconnect disabled: $message',
        name: 'WsService',
      );
      return;
    }

    developer.log('❌ WS connect error: $message', name: 'WsService');
    _scheduleReconnect();
  }

  void _handleSocketError(Object error) {
    final message = _redactSensitive('$error');
    if (_looksLikeAuthFailure(error)) {
      _authFailure = true;
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();
      _sub?.cancel();
      _channel = null;
      _isConnected = false;
      developer.log(
        '🔒 WS closed by auth error; reconnect disabled: $message',
        name: 'WsService',
      );
      return;
    }

    developer.log('❌ WS stream error: $message', name: 'WsService');
    _scheduleReconnect();
  }

  void _handleSocketDone() {
    if (_authFailure || _disposed) return;
    _scheduleReconnect();
  }

  bool _looksLikeAuthFailure(Object error) {
    final value = '$error'.toLowerCase();
    return value.contains('401') ||
        value.contains('403') ||
        value.contains('unauthorized') ||
        value.contains('forbidden') ||
        value.contains('expired') ||
        value.contains('invalid token') ||
        value.contains('was not upgraded to websocket');
  }

  void _resubscribeActiveIncident() {
    final incidentId = _activeIncidentId;
    if (incidentId != null) {
      _sendSubscribeIncident(incidentId);
    }
  }

  void _sendSubscribeIncident(int incidentId) {
    send({'type': 'subscribe_incident', 'incident_id': incidentId});
    developer.log('📡 WS subscribe incident:$incidentId', name: 'WsService');
  }

  String _redactSensitive(String value) {
    return value.replaceAll(RegExp(r'token=[^&\s]+'), 'token=<REDACTED>');
  }
}

/// Provider Riverpod del WsService (singleton global).
final wsServiceProvider = Provider<WsService>((ref) {
  return WsService();
});

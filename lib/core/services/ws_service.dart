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

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream de todos los mensajes WS recibidos.
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  /// Filtra mensajes por tipo de evento.
  Stream<Map<String, dynamic>> on(String type) =>
      messages.where((m) => m['type'] == type);

  /// Conecta al WS usando el JWT guardado en SecureStorage.
  Future<void> connect() async {
    if (_disposed) return;
    final token = await SecureStorageService().getToken();
    if (token == null || token.isEmpty) return;

    // Derivar WS URL desde la base URL HTTP
    final baseUrl = Env.baseUrl; // e.g. https://host/api/v1
    final wsBase = baseUrl
        .replaceFirst('/api/v1', '')
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$wsBase/ws?token=$token');

    developer.log('🔌 WS connecting: $uri', name: 'WsService');
    try {
      _channel = WebSocketChannel.connect(uri);
      _reconnectAttempts = 0;
      _startHeartbeat();

      _sub = _channel!.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            // Responder a ping del servidor
            if (msg['type'] == 'ping') {
              send({'type': 'pong'});
              return;
            }
            developer.log('📨 WS recv: ${msg["type"]}', name: 'WsService');
            if (!_controller.isClosed) _controller.add(msg);
          } catch (_) {}
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      developer.log('❌ WS connect error: $e', name: 'WsService');
      _scheduleReconnect();
    }
  }

  /// Envía un mensaje JSON al servidor.
  void send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  /// Cierra la conexión definitivamente (al hacer logout).
  void close() {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  /// Reinicia para una nueva sesión (al hacer login de nuevo).
  void reset() {
    _disposed = false;
    _reconnectAttempts = 0;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send({'type': 'ping'});
    });
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _heartbeatTimer?.cancel();
    _sub?.cancel();
    _channel = null;

    final delay = min(pow(2, _reconnectAttempts).toInt(), 30);
    _reconnectAttempts++;
    developer.log(
      '⏱ WS reconnect in ${delay}s (attempt $_reconnectAttempts)',
      name: 'WsService',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }
}

/// Provider Riverpod del WsService (singleton global).
final wsServiceProvider = Provider<WsService>((ref) {
  return WsService();
});

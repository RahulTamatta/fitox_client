import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef CallEventHandler = void Function(Map<String, dynamic> data);

class CallSignalingService {
  static IO.Socket? _socket;
  static String? _currentUserId;

  // Event handlers
  static CallEventHandler? onIncoming;
  static CallEventHandler? onAccepted;
  static CallEventHandler? onRejected;
  static CallEventHandler? onCanceled;
  static CallEventHandler? onEnded;
  static CallEventHandler? onTimeout;
  static CallEventHandler? onUnavailable;

  static Future<void> init(String userId) async {
    if (_socket != null && _socket!.connected && _currentUserId == userId) {
      return;
    }
    _currentUserId = userId;
    // Use production server for all platforms; localhost is not reachable on devices
    final url = 'https://fitox-server.onrender.com';

    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.on('connect', (_) {
      // Support both 'join' and 'register' server-side
      _socket!.emit('join', userId);
    });

    // Error and state handlers for better diagnostics and state awareness
    _socket!.on('connect_error', (e) {
      try {
        // No external state here; providers can add custom handlers if needed
        // ignore: avoid_print
        print('[CallSignalingService] connect_error: $e');
      } catch (_) {}
    });
    _socket!.on('connect_timeout', (_) {
      try {
        // ignore: avoid_print
        print('[CallSignalingService] connect_timeout');
      } catch (_) {}
    });
    _socket!.on('error', (e) {
      try {
        // ignore: avoid_print
        print('[CallSignalingService] error: $e');
      } catch (_) {}
    });
    _socket!.on('disconnect', (reason) {
      try {
        // ignore: avoid_print
        print('[CallSignalingService] disconnect: $reason');
      } catch (_) {}
    });

    _socket!.on('call:incoming', (data) {
      if (data is Map) onIncoming?.call(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:accepted', (data) {
      if (data is Map) onAccepted?.call(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:rejected', (data) {
      if (data is Map) onRejected?.call(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:canceled', (data) {
      if (data is Map) onCanceled?.call(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:ended', (data) {
      if (data is Map) onEnded?.call(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:timeout', (data) {
      if (data is Map) onTimeout?.call(Map<String, dynamic>.from(data));
    });
    _socket!.on('call:unavailable', (data) {
      if (data is Map) onUnavailable?.call(Map<String, dynamic>.from(data));
    });

    _socket!.connect();
  }

  static bool get isConnected => _socket?.connected == true;

  static void invite({
    required String from,
    required String to,
    required String channelName,
    required String callType, // 'audio' | 'video'
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call:invite', {
      'from': from,
      'to': to,
      'channelName': channelName,
      'callType': callType,
    });
  }

  static void accept({
    required String from,
    required String to,
    required String channelName,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call:accept', {
      'from': from,
      'to': to,
      'channelName': channelName,
    });
  }

  static void reject({
    required String from,
    required String to,
    required String channelName,
    String? reason,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call:reject', {
      'from': from,
      'to': to,
      'channelName': channelName,
      'reason': reason,
    });
  }

  static void cancel({
    required String from,
    required String to,
    required String channelName,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call:cancel', {
      'from': from,
      'to': to,
      'channelName': channelName,
    });
  }

  static void end({
    required String from,
    required String to,
    required String channelName,
    int? duration,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('call:end', {
      'from': from,
      'to': to,
      'channelName': channelName,
      'duration': duration,
    });
  }

  static void dispose() {
    try {
      _socket?.dispose();
      _socket = null;
      _currentUserId = null;
    } catch (_) {}
  }
}

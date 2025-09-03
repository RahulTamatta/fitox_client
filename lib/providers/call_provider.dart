import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/agora/agora_rtc_service.dart';
import '../services/subscription_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../services/call_signaling_service.dart';

enum CallState { idle, connecting, ringing, connected, reconnecting, ended }

enum CallType { audio, video }

class CallProvider with ChangeNotifier {
  CallState _callState = CallState.idle;
  CallType _callType = CallType.video;
  bool _isMuted = false;
  bool _isCameraOn = true;
  bool _isFrontCamera = true;
  bool _isRemoteUserJoined = false;
  int? _remoteUid;
  String? _channelName;
  String? _error;
  bool _isConnected = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  String? _callerId;
  String? _calleeId;
  String? _selfId;
  // Store last incoming invite metadata for UI to consume
  String? _incomingFromId;
  String? _incomingChannelName;
  bool _incomingInitDone = false;

  CallState get callState => _callState;
  CallType get callType => _callType;
  bool get isMuted => _isMuted;
  bool get isCameraOn => _isCameraOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get isRemoteUserJoined => _isRemoteUserJoined;
  int? get remoteUid => _remoteUid;
  String? get channelName => _channelName;
  String? get error => _error;
  bool get isConnected => _isConnected;
  String? get incomingFromId => _incomingFromId;
  String? get incomingChannelName => _incomingChannelName;

  Future<bool> startCall({
    required String callerId,
    required String calleeId,
    required CallType type,
  }) async {
    try {
      print(
        ' [CallProvider] startCall => callerId=$callerId calleeId=$calleeId type=$type',
      );
      // Check subscription
      final canCall = await SubscriptionService.validateAction(
        userId: callerId,
        action: 'call',
      );

      print(' [CallProvider] validateAction(call) => $canCall');
      if (!canCall) {
        _error = 'Subscription required for calls';
        notifyListeners();
        print(' [CallProvider] Subscription not allowed, aborting call');
        return false;
      }

      _callType = type;
      _callState = CallState.connecting;
      _callerId = callerId;
      _calleeId = calleeId;
      _selfId = callerId;
      _channelName = _generateChannelName(callerId, calleeId);
      notifyListeners();
      print(
        '  [CallProvider] Initializing RTC and signaling. channelName=$_channelName (len=${_channelName!.length})',
      );

      // Initialize RTC service
      final rtcInitOk = await AgoraRtcService.initialize();
      print('  [CallProvider] AgoraRtcService.initialize => $rtcInitOk');
      // Initialize signaling service
      await CallSignalingService.init(callerId);
      print(
        ' [CallProvider] CallSignalingService.init done (connected=${CallSignalingService.isConnected})',
      );

      // Set up callbacks
      AgoraRtcService.onUserJoined = _handleUserJoined;
      AgoraRtcService.onUserOffline = _handleUserOffline;
      AgoraRtcService.onConnectionStateChanged = _handleConnectionStateChanged;
      AgoraRtcService.onTokenPrivilegeWillExpire = _handleTokenExpire;
      AgoraRtcService.onError = _handleError;

      // Start connectivity monitoring
      _startConnectivityMonitoring();
      print(' [CallProvider] Connectivity monitoring started');

      // Join channel
      final success = await AgoraRtcService.joinChannel(
        channelName: _channelName!,
        userId: callerId,
        isVideoCall: type == CallType.video,
      );

      print(' [CallProvider] joinChannel => $success');
      if (success) {
        _callState = CallState.ringing;
        _isCameraOn = type == CallType.video;
        notifyListeners();
        print(' [CallProvider] Sending call invite to $calleeId');
        // Send call invite via signaling
        CallSignalingService.invite(
          from: callerId,
          to: calleeId,
          channelName: _channelName!,
          callType: type == CallType.video ? 'video' : 'audio',
        );
        // Listen for responses
        _bindSignalingHandlers();
        print(' [CallProvider] Signaling handlers bound');
        return true;
      } else {
        _callState = CallState.ended;
        _error = 'Failed to join call';
        notifyListeners();
        print(' [CallProvider] Failed to join channel. Error=$_error');
        return false;
      }
    } catch (e) {
      _error = 'Failed to start call: $e';
      _callState = CallState.ended;
      notifyListeners();
      print(' [CallProvider] Exception in startCall: $e');
      return false;
    }
  }

  Future<void> endCall() async {
    try {
      print(' [CallProvider] endCall');
      await AgoraRtcService.leaveChannel();
      // Notify peer
      if (_callerId != null &&
          _calleeId != null &&
          _channelName != null &&
          _selfId != null) {
        final me = _selfId!;
        final other = me == _callerId ? _calleeId! : _callerId!;
        print(
          ' [CallProvider] Notifying peer end: from=$me to=$other channelName=$_channelName',
        );
        CallSignalingService.end(
          from: me,
          to: other,
          channelName: _channelName!,
        );
      }
      _callState = CallState.ended;
      _isRemoteUserJoined = false;
      _remoteUid = null;
      _channelName = null;
      _connectivitySubscription?.cancel();
      notifyListeners();
      print(' [CallProvider] Call state reset');
    } catch (e) {
      print('Failed to end call: $e');
    }
  }

  // Incoming call actions (to be used by IncomingCallScreen)
  // Listen for incoming calls globally (call once after login)
  Future<void> listenForIncomingCalls(String currentUserId) async {
    if (_incomingInitDone) return;
    try {
      await CallSignalingService.init(currentUserId);
      // Bind only once
      CallSignalingService.onIncoming = (data) {
        try {
          final from = (data['from'] ?? '').toString();
          final ch = (data['channelName'] ?? '').toString();
          final typeStr = (data['callType'] ?? 'video').toString();
          final t = typeStr == 'audio' ? CallType.audio : CallType.video;
          _incomingFromId = from;
          _incomingChannelName = ch;
          _callType = t;
          _callerId = from;
          _calleeId = currentUserId;
          _selfId = currentUserId;
          _channelName = ch;
          _callState = CallState.ringing;
          notifyListeners();
        } catch (_) {}
      };
      // Also keep other signaling handlers ready (timeout/cancel, etc.)
      _bindSignalingHandlers();
      _incomingInitDone = true;
    } catch (e) {
      _error = 'Failed to init incoming calls: $e';
      notifyListeners();
    }
  }

  Future<void> acceptIncomingCall({
    required String currentUserId,
    required String otherUserId,
    required String channelName,
    required CallType type,
  }) async {
    try {
      _callType = type;
      _callState = CallState.connecting;
      _callerId = otherUserId; // caller is the other user
      _calleeId = currentUserId; // current user is callee
      _selfId = currentUserId;
      _channelName = channelName;
      notifyListeners();

      await AgoraRtcService.initialize();
      await CallSignalingService.init(currentUserId);
      _bindSignalingHandlers();

      final success = await AgoraRtcService.joinChannel(
        channelName: channelName,
        userId: currentUserId,
        isVideoCall: type == CallType.video,
      );
      if (success) {
        _callState =
            CallState.connected; // will become connected when remote joins
        _isCameraOn = type == CallType.video;
        notifyListeners();
        // Notify caller
        CallSignalingService.accept(
          from: currentUserId,
          to: otherUserId,
          channelName: channelName,
        );
      } else {
        _callState = CallState.ended;
        _error = 'Failed to join call';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to accept call: $e';
      _callState = CallState.ended;
      notifyListeners();
    }
  }

  void rejectIncomingCall({
    required String currentUserId,
    required String otherUserId,
    required String channelName,
    String? reason,
  }) {
    try {
      CallSignalingService.reject(
        from: currentUserId,
        to: otherUserId,
        channelName: channelName,
        reason: reason,
      );
      _callState = CallState.ended;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reject call: $e';
      notifyListeners();
    }
  }

  Future<void> toggleMute() async {
    try {
      await AgoraRtcService.toggleMute();
      _isMuted = !_isMuted;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle mute: $e';
      notifyListeners();
    }
  }

  Future<void> toggleCamera() async {
    try {
      if (_callType == CallType.video) {
        await AgoraRtcService.toggleCamera();
        _isCameraOn = !_isCameraOn;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle camera: $e';
      notifyListeners();
    }
  }

  Future<void> switchCamera() async {
    try {
      if (_callType == CallType.video && _isCameraOn) {
        await AgoraRtcService.switchCamera();
        _isFrontCamera = !_isFrontCamera;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to switch camera: $e';
      notifyListeners();
    }
  }

  void _handleUserJoined(int uid, int elapsed) {
    _remoteUid = uid;
    _isRemoteUserJoined = true;
    _callState = CallState.connected;
    notifyListeners();
  }

  void _handleUserOffline(int uid, UserOfflineReasonType reason) {
    if (uid == _remoteUid) {
      _isRemoteUserJoined = false;
      _remoteUid = null;

      if (reason == UserOfflineReasonType.userOfflineQuit) {
        _callState = CallState.ended;
      }
      notifyListeners();
    }
  }

  void _handleConnectionStateChanged(
    ConnectionStateType state,
    ConnectionChangedReasonType reason,
  ) {
    switch (state) {
      case ConnectionStateType.connectionStateConnecting:
        _callState = CallState.connecting;
        break;
      case ConnectionStateType.connectionStateConnected:
        if (_isRemoteUserJoined) {
          _callState = CallState.connected;
        }
        break;
      case ConnectionStateType.connectionStateReconnecting:
        _callState = CallState.reconnecting;
        break;
      case ConnectionStateType.connectionStateFailed:
        _callState = CallState.ended;
        _error = 'Connection failed';
        break;
      case ConnectionStateType.connectionStateDisconnected:
        _callState = CallState.ended;
        break;
    }
    notifyListeners();
  }

  void _handleTokenExpire() {
    // Token renewal is handled automatically in AgoraRtcService
    print('Token will expire, renewing...');
  }

  void _handleError(ErrorCodeType err) {
    _error = 'Call error: ${err.toString()}';
    notifyListeners();
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      _isConnected = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

  void _bindSignalingHandlers() {
    CallSignalingService.onAccepted = (data) {
      // Peer accepted; if we are ringing, move to connecting/connected
      if (_callState == CallState.ringing ||
          _callState == CallState.connecting) {
        _callState =
            _isRemoteUserJoined ? CallState.connected : CallState.connecting;
        notifyListeners();
      }
    };
    CallSignalingService.onRejected = (data) {
      _error = 'Call rejected';
      _callState = CallState.ended;
      notifyListeners();
    };
    CallSignalingService.onCanceled = (data) {
      _error = 'Call canceled';
      _callState = CallState.ended;
      notifyListeners();
    };
    CallSignalingService.onEnded = (data) {
      _callState = CallState.ended;
      notifyListeners();
    };
    CallSignalingService.onTimeout = (data) {
      _error = 'Call timed out';
      _callState = CallState.ended;
      notifyListeners();
    };
    CallSignalingService.onUnavailable = (data) {
      _error = 'User unavailable';
      _callState = CallState.ended;
      notifyListeners();
    };
  }

  Widget? getLocalVideoView() {
    if (_callType == CallType.video && _isCameraOn) {
      return AgoraRtcService.createLocalVideoView();
    }
    return null;
  }

  Widget? getRemoteVideoView() {
    if (_callType == CallType.video && _remoteUid != null) {
      return AgoraRtcService.createRemoteVideoView(_remoteUid!);
    }
    return null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    endCall();
    super.dispose();
  }

  // Generate a short, Agora-compliant channel name (<= 64 chars, [A-Za-z0-9_])
  String _generateChannelName(String callerId, String calleeId) {
    // Use base36 timestamp and short prefixes of IDs to keep it compact and readable.
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    String safe(String s) {
      // Restrict to alphanumeric and underscore; replace others with underscore
      final filtered = s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
      return filtered.length > 8 ? filtered.substring(0, 8) : filtered;
    }

    final c1 = safe(callerId);
    final c2 = safe(calleeId);
    final name = 'c_${ts}_${c1}_${c2}';
    // Ensure final length <= 64 (highly likely already). If longer, trim end.
    return name.length <= 64 ? name : name.substring(0, 64);
  }
}

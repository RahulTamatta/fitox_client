import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/agora/agora_rtc_service.dart';
import '../services/subscription_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

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

  Future<bool> startCall({
    required String callerId,
    required String calleeId,
    required CallType type,
  }) async {
    try {
      // Check subscription
      final canCall = await SubscriptionService.validateAction(
        userId: callerId,
        action: 'call',
      );

      if (!canCall) {
        _error = 'Subscription required for calls';
        notifyListeners();
        return false;
      }

      _callType = type;
      _callState = CallState.connecting;
      _channelName = 'call_${callerId}_${calleeId}_${DateTime.now().millisecondsSinceEpoch}';
      notifyListeners();

      // Initialize RTC service
      await AgoraRtcService.initialize();
      
      // Set up callbacks
      AgoraRtcService.onUserJoined = _handleUserJoined;
      AgoraRtcService.onUserOffline = _handleUserOffline;
      AgoraRtcService.onConnectionStateChanged = _handleConnectionStateChanged;
      AgoraRtcService.onTokenPrivilegeWillExpire = _handleTokenExpire;
      AgoraRtcService.onError = _handleError;

      // Start connectivity monitoring
      _startConnectivityMonitoring();

      // Join channel
      final success = await AgoraRtcService.joinChannel(
        channelName: _channelName!,
        userId: callerId,
        isVideoCall: type == CallType.video,
      );

      if (success) {
        _callState = CallState.ringing;
        _isCameraOn = type == CallType.video;
        notifyListeners();
        return true;
      } else {
        _callState = CallState.ended;
        _error = 'Failed to join call';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to start call: $e';
      _callState = CallState.ended;
      notifyListeners();
      return false;
    }
  }

  Future<void> endCall() async {
    try {
      await AgoraRtcService.leaveChannel();
      _callState = CallState.ended;
      _isRemoteUserJoined = false;
      _remoteUid = null;
      _channelName = null;
      _connectivitySubscription?.cancel();
      notifyListeners();
    } catch (e) {
      print('Failed to end call: $e');
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

  void _handleConnectionStateChanged(ConnectionStateType state, ConnectionChangedReasonType reason) {
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
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
      notifyListeners();
    });
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
}

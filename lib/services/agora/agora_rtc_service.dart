import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'agora_token_service.dart';

class AgoraRtcService {
  static RtcEngine? _engine;
  static String? _currentToken;
  static String? _currentChannel;
  static int? _currentUid;
  static bool _isJoined = false;
  static bool _engineInitialized = false;

  // Callbacks
  static Function(int uid, int elapsed)? onUserJoined;
  static Function(int uid, UserOfflineReasonType reason)? onUserOffline;
  static Function(
    ConnectionStateType state,
    ConnectionChangedReasonType reason,
  )?
  onConnectionStateChanged;
  static Function()? onTokenPrivilegeWillExpire;
  static Function(ErrorCodeType err)? onError;

  static Future<bool> initialize() async {
    try {
      _engine ??= createAgoraRtcEngine();

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Joined channel: ${connection.channelId}');
            _isJoined = true;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('User joined: $remoteUid');
            onUserJoined?.call(remoteUid, elapsed);
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            print('User offline: $remoteUid');
            onUserOffline?.call(remoteUid, reason);
          },
          onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
          ) {
            print('Connection state changed: $state, reason: $reason');
            onConnectionStateChanged?.call(state, reason);
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            print('Token will expire, renewing...');
            onTokenPrivilegeWillExpire?.call();
            _renewToken();
          },
          onError: (ErrorCodeType err, String msg) {
            print('RTC Error: $err, $msg');
            onError?.call(err);
          },
        ),
      );

      return true;
    } catch (e) {
      print('Failed to initialize Agora RTC: $e');
      return false;
    }
  }

  static Future<bool> requestPermissions() async {
    final permissions = [Permission.camera, Permission.microphone];
    final statuses = await permissions.request();

    return statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );
  }

  static Future<bool> joinChannel({
    required String channelName,
    required String userId,
    bool isVideoCall = true,
  }) async {
    try {
      if (!await requestPermissions()) {
        print('Permissions not granted');
        return false;
      }

      // Sanitize and validate channel name per Agora limits
      final sanitized = _sanitizeChannelName(channelName);
      if (sanitized.isEmpty) {
        print('Invalid channel name after sanitization');
        return false;
      }
      if (sanitized.length > 64) {
        print('Channel name too long (>64) even after sanitization');
        return false;
      }

      // Derive a valid 32-bit unsigned UID deterministically from userId
      final uid = _uidFromUserId(userId);

      // Get RTC token from backend
      final tokenData = await AgoraTokenService.getRtcToken(
        channelName: sanitized,
        uid: uid,
        role: 'publisher',
      );

      if (tokenData == null) {
        print('Failed to get RTC token');
        return false;
      }

      _currentToken = tokenData['token'];
      _currentChannel = sanitized;
      _currentUid = uid;

      // Initialize engine with app ID if not already
      if (!_engineInitialized) {
        await _engine!.initialize(
          RtcEngineContext(
            appId: tokenData['appId'],
            channelProfile: ChannelProfileType.channelProfileCommunication,
          ),
        );
        await _engine!.enableAudio();
        // Route audio to speakerphone by default for better UX
        await _engine!.setDefaultAudioRouteToSpeakerphone(true);
        if (isVideoCall) {
          await _engine!.enableVideo();
        } else {
          await _engine!.disableVideo();
        }
        _engineInitialized = true;
      } else {
        // Ensure audio/video tracks reflect current call type
        if (isVideoCall) {
          await _engine!.enableVideo();
        } else {
          await _engine!.disableVideo();
        }
      }

      final options = ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      );

      await _engine!.joinChannel(
        token: _currentToken!,
        channelId: sanitized,
        uid: uid,
        options: options,
      );

      return true;
    } catch (e) {
      print('Failed to join channel: $e');
      return false;
    }
  }

  static Future<void> leaveChannel() async {
    try {
      if (_engine == null) return;
      await _engine!.leaveChannel();
      _isJoined = false;
      _currentToken = null;
      _currentChannel = null;
      _currentUid = null;
    } catch (e) {
      print('Failed to leave channel: $e');
    }
  }

  static bool _isMuted = false;

  static Future<void> toggleMute() async {
    try {
      if (_engine == null) throw 'Engine not initialized';
      _isMuted = !_isMuted;
      await _engine!.muteLocalAudioStream(_isMuted);
    } catch (e) {
      print('Failed to toggle mute: $e');
    }
  }

  static bool _isCameraOff = false;

  static Future<void> toggleCamera() async {
    try {
      if (_engine == null) throw 'Engine not initialized';
      _isCameraOff = !_isCameraOff;
      await _engine!.muteLocalVideoStream(_isCameraOff);
    } catch (e) {
      print('Failed to toggle camera: $e');
    }
  }

  static Future<void> switchCamera() async {
    try {
      if (_engine == null) throw 'Engine not initialized';
      await _engine!.switchCamera();
    } catch (e) {
      print('Failed to switch camera: $e');
    }
  }

  static Future<void> _renewToken() async {
    if (_currentChannel == null || _currentUid == null) return;

    try {
      final tokenData = await AgoraTokenService.getRtcToken(
        channelName: _currentChannel!,
        uid: _currentUid!,
        role: 'publisher',
      );

      if (tokenData != null) {
        if (_engine != null) {
          await _engine!.renewToken(tokenData['token']);
        }
        _currentToken = tokenData['token'];
      }
    } catch (e) {
      print('Failed to renew token: $e');
    }
  }

  static Widget createLocalVideoView() {
    if (_engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  static Widget createRemoteVideoView(int uid) {
    if (_engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: uid),
        connection: RtcConnection(channelId: _currentChannel),
      ),
    );
  }

  static Future<void> dispose() async {
    try {
      await leaveChannel();
      if (_engine != null) {
        await _engine!.release();
      }
      _engine = null;
      _engineInitialized = false;
    } catch (e) {
      print('Failed to dispose Agora RTC: $e');
    }
  }

  static bool get isJoined => _isJoined;
  static RtcEngine? get engine => _engine;

  // Ensure channel name uses only [A-Za-z0-9_], replace others with '_', and hard-cap to 64 chars
  static String _sanitizeChannelName(String name) {
    if (name.isEmpty) return '';
    final filtered = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return filtered.length <= 64 ? filtered : filtered.substring(0, 64);
  }

  // Deterministically derive a 32-bit unsigned UID from a string userId
  static int _uidFromUserId(String userId) {
    final parsed = int.tryParse(userId);
    if (parsed != null && parsed >= 0 && parsed <= 0xFFFFFFFF) {
      return parsed;
    }
    // FNV-1a 32-bit hash
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime = 0x01000193;
    int hash = fnvOffset;
    for (final c in userId.codeUnits) {
      hash ^= c;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    // Ensure non-negative in Dart int representation
    return hash & 0xFFFFFFFF;
  }
}

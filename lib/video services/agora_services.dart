import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  late RtcEngine engine;
  final String appId; // Replace with your Agora App ID
  bool _isMuted = false;
  bool _isCameraFront = true;
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngineEventHandler _eventHandler; // Store the event handler

  AgoraService({required this.appId});

  // Initialize Agora Engine
  Future<void> initialize() async {
    // Request camera and microphone permissions
    await [Permission.camera, Permission.microphone].request();

    // Create and initialize the Agora engine
    engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Enable video
    await engine.enableVideo();

    // Set up event handlers
    _eventHandler = RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _localUserJoined = true;
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        _remoteUid = remoteUid;
      },
      onUserOffline: (
        RtcConnection connection,
        int remoteUid,
        UserOfflineReasonType reason,
      ) {
        _remoteUid = null;
      },
      onError: (ErrorCodeType err, String msg) {
        print('[AgoraService] Error: $err, $msg');
      },
    );
    engine.registerEventHandler(_eventHandler);
  }

  // Join a channel
  Future<void> joinChannel(String token, String channelName, int uid) async {
    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  // Leave the channel
  Future<void> leaveChannel() async {
    await engine.leaveChannel();
    _remoteUid = null;
    _localUserJoined = false;
  }

  // Toggle mute microphone
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await engine.muteLocalAudioStream(_isMuted);
  }

  // Switch camera
  Future<void> switchCamera() async {
    _isCameraFront = !_isCameraFront;
    await engine.switchCamera();
  }

  // Clean up resources
  Future<void> dispose() async {
    await engine.leaveChannel();
    engine.unregisterEventHandler(_eventHandler); // Pass the stored handler
    await engine.release();
  }

  // Getters
  bool get isMuted => _isMuted;
  bool get isCameraFront => _isCameraFront;
  int? get remoteUid => _remoteUid;
  bool get localUserJoined => _localUserJoined;
}

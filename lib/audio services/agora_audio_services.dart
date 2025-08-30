import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraAudioService {
  late RtcEngine engine;
  final String appId; // Replace with your Agora App ID
  bool _isMuted = false;
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngineEventHandler _eventHandler;

  AgoraAudioService({required this.appId});

  // Initialize Agora Engine for audio-only
  Future<void> initialize() async {
    // Request microphone permission
    await [Permission.microphone].request();

    // Create and initialize the Agora engine
    engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Disable video and enable audio
    await engine.disableVideo();
    await engine.enableAudio();

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
        print('[AgoraAudioService] Error: $err, $msg');
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

  // Clean up resources
  Future<void> dispose() async {
    await engine.leaveChannel();
    engine.unregisterEventHandler(_eventHandler);
    await engine.release();
  }

  // Getters
  bool get isMuted => _isMuted;
  int? get remoteUid => _remoteUid;
  bool get localUserJoined => _localUserJoined;
}

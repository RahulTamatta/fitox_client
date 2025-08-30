import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'agora_services.dart';

class VideoCallScreen extends StatefulWidget {
  final int uid;
  final String? sessionId;

  const VideoCallScreen({super.key, required this.uid, this.sessionId});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late AgoraService _agoraService;
  final String appId = 'c21b8680229d40efa4ecba917490b677';
  final String _token = ''; // For testing, use token only in production
  late String _channelName;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showInviteDialog = true;

  @override
  void initState() {
    super.initState();
    _agoraService = AgoraService(appId: appId);
    _channelName = widget.sessionId ?? const Uuid().v4();
    _showInviteDialogIfNeeded();
  }

  Future<void> _showInviteDialogIfNeeded() async {
    if (widget.sessionId != null) {
      await _initCall();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInvitedDialog();
      });
    }
  }

  Future<void> _showInvitedDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Invite Trainer to Video Call',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share this Session ID with your trainer:',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  _channelName,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _channelName));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Session ID copied to clipboard',
                              style: GoogleFonts.roboto(color: Colors.white),
                            ),
                            backgroundColor: Colors.blue[900],
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text('Copy', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Share.share(
                          'Join my gym video call! Session ID: $_channelName',
                          subject: 'Gym Video Call Invitation',
                        );
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: Text('Share', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showInviteDialog = false;
                  });
                  Navigator.pop(context);
                  _initCall();
                },
                child: Text(
                  'Start Call',
                  style: GoogleFonts.poppins(
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _initCall() async {
    try {
      await _agoraService.initialize();
      await _agoraService.joinChannel(_token, _channelName, widget.uid);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to start call: $e';
      });
    }
  }

  @override
  void dispose() {
    _agoraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          'Starting Video Call...',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Stack(
                    children: [
                      // Remote view
                      Center(
                        child:
                            _errorMessage != null
                                ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: Colors.red[300],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                : _agoraService.remoteUid != null
                                ? AgoraVideoView(
                                  controller: VideoViewController.remote(
                                    rtcEngine: _agoraService.engine,
                                    canvas: VideoCanvas(
                                      uid: _agoraService.remoteUid!,
                                    ),
                                    connection: RtcConnection(
                                      channelId: _channelName,
                                    ),
                                  ),
                                )
                                : Text(
                                  'Waiting for trainer to join...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                      ),
                      // Local view
                      if (_agoraService.localUserJoined &&
                          _errorMessage == null)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 120,
                            height: 180,
                            margin: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: _agoraService.engine,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Session ID banner
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Session: ${_channelName.substring(0, 8)}...',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: _channelName),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Session ID copied',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.blue[900],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Control buttons
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildControlButton(
                                icon:
                                    _agoraService.isMuted
                                        ? Icons.mic_off
                                        : Icons.mic,
                                onPressed: () {
                                  setState(() {
                                    _agoraService.toggleMute();
                                  });
                                },
                              ),
                              const SizedBox(width: 20),
                              _buildControlButton(
                                icon: Icons.switch_camera,
                                onPressed: () {
                                  setState(() {
                                    _agoraService.switchCamera();
                                  });
                                },
                              ),
                              const SizedBox(width: 20),
                              _buildControlButton(
                                icon: Icons.call_end,
                                color: Colors.red,
                                onPressed: () {
                                  _agoraService.leaveChannel();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black54,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: onPressed,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/call_provider.dart';
import '../../themes/app_theme.dart';

class CallScreen extends StatefulWidget {
  final String calleeId;
  final String calleeName;
  final CallType callType;
  final String? calleeImage;

  const CallScreen({
    super.key,
    required this.calleeId,
    required this.calleeName,
    required this.callType,
    this.calleeImage,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCall();
    });
  }

  Future<void> _startCall() async {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    final success = await callProvider.startCall(
      callerId: 'current_user_id', // Get from SharedPreferences
      calleeId: widget.calleeId,
      type: widget.callType,
    );

    if (!success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CallProvider>(
        builder: (context, callProvider, child) {
          return SafeArea(
            child: Stack(
              children: [
                // Video views
                if (widget.callType == CallType.video) ...[
                  // Remote video (full screen)
                  if (callProvider.isRemoteUserJoined)
                    Positioned.fill(
                      child: callProvider.getRemoteVideoView() ?? Container(),
                    ),
                  
                  // Local video (small overlay)
                  if (callProvider.isCameraOn)
                    Positioned(
                      top: 50.h,
                      right: 20.w,
                      child: Container(
                        width: 120.w,
                        height: 160.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: callProvider.getLocalVideoView() ?? Container(),
                        ),
                      ),
                    ),
                ],

                // Audio call UI
                if (widget.callType == CallType.audio || !callProvider.isRemoteUserJoined)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.8),
                            AppTheme.primaryColor,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Profile image
                          CircleAvatar(
                            radius: 80.r,
                            backgroundImage: widget.calleeImage != null
                                ? NetworkImage(widget.calleeImage!)
                                : null,
                            child: widget.calleeImage == null
                                ? Icon(Icons.person, size: 80.sp, color: Colors.white)
                                : null,
                          ),
                          SizedBox(height: 24.h),
                          
                          // Name
                          Text(
                            widget.calleeName,
                            style: GoogleFonts.poppins(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          
                          // Call status
                          Text(
                            _getCallStatusText(callProvider.callState),
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Connection status banner
                if (!callProvider.isConnected)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(12.h),
                      color: Colors.orange,
                      child: Text(
                        'Poor connection - Reconnecting...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Control buttons
                Positioned(
                  bottom: 50.h,
                  left: 0,
                  right: 0,
                  child: _buildControlButtons(callProvider),
                ),

                // Error message
                if (callProvider.error != null)
                  Positioned(
                    top: 100.h,
                    left: 20.w,
                    right: 20.w,
                    child: Container(
                      padding: EdgeInsets.all(12.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        callProvider.error!,
                        style: GoogleFonts.poppins(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButtons(CallProvider callProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute button
        _buildControlButton(
          icon: callProvider.isMuted ? Symbols.mic_off : Symbols.mic,
          onTap: callProvider.toggleMute,
          backgroundColor: callProvider.isMuted ? Colors.red : Colors.white.withOpacity(0.2),
        ),

        // Camera button (video calls only)
        if (widget.callType == CallType.video)
          _buildControlButton(
            icon: callProvider.isCameraOn ? Symbols.videocam : Symbols.videocam_off,
            onTap: callProvider.toggleCamera,
            backgroundColor: callProvider.isCameraOn ? Colors.white.withOpacity(0.2) : Colors.red,
          ),

        // Switch camera button (video calls only)
        if (widget.callType == CallType.video)
          _buildControlButton(
            icon: Symbols.flip_camera_ios,
            onTap: callProvider.switchCamera,
            backgroundColor: Colors.white.withOpacity(0.2),
          ),

        // End call button
        _buildControlButton(
          icon: Symbols.call_end,
          onTap: () async {
            await callProvider.endCall();
            Navigator.pop(context);
          },
          backgroundColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56.w,
        height: 56.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  String _getCallStatusText(CallState state) {
    switch (state) {
      case CallState.connecting:
        return 'Connecting...';
      case CallState.ringing:
        return 'Ringing...';
      case CallState.connected:
        return 'Connected';
      case CallState.reconnecting:
        return 'Reconnecting...';
      case CallState.ended:
        return 'Call ended';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    callProvider.endCall();
    super.dispose();
  }
}

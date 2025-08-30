import 'package:fit_talk/audio%20services/audio_screen.dart';
import 'package:fit_talk/screens/home/services/home_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../themes/app_theme.dart';
import '../../video services/video_call_screen.dart';

class TrainerDetailsScreen extends StatefulWidget {
  final Professional trainer;

  const TrainerDetailsScreen({super.key, required this.trainer});

  @override
  _TrainerDetailsScreenState createState() => _TrainerDetailsScreenState();
}

class _TrainerDetailsScreenState extends State<TrainerDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSendingMessage = false;

  // Mock function to send a message (replace with actual backend call)
  Future<void> _sendMessage(String message) async {
    setState(() {
      _isSendingMessage = true;
    });
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (kDebugMode) {
        print('Message sent to ${widget.trainer.name}: $message');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent to ${widget.trainer.name}')),
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  // Mock function for audio call (replace with actual call service integration)
  // Function to start audio call
  void _startAudioCall() {
    if (widget.trainer.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Trainer ID is missing',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => AudioCallScreen(uid: 1234)));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Initiating audio call with ${widget.trainer.name}',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  // Mock function for video call (replace with actual call service integration)
  void _startVideoCall() {
    if (widget.trainer.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: Trainer ID is missing',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => VideoCallScreen(uid: 1222)));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Initiating video call with ${widget.trainer.name}',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trainer = widget.trainer;
    final profileImage =
        trainer.profileImage.isNotEmpty
            ? trainer.profileImage
            : 'https://picsum.photos/200';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                profileImage,
                trainer,
              ).animate().fadeIn(duration: 600.ms),
              SizedBox(height: 24.h),
              _buildDetailsSection(
                trainer,
              ).animate().slideY(begin: 0.2, end: 0, duration: 600.ms),
              SizedBox(height: 24.h),
              _buildActionButtons().animate().fadeIn(duration: 600.ms),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String profileImage, Professional trainer) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              Symbols.arrow_back_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: profileImage,
                imageBuilder:
                    (context, imageProvider) => CircleAvatar(
                      radius: 50.r,
                      backgroundImage: imageProvider,
                    ),
                placeholder:
                    (context, url) => CircleAvatar(
                      radius: 50.r,
                      child: CircularProgressIndicator(strokeWidth: 2.w),
                    ),
                errorWidget:
                    (context, url, error) => CircleAvatar(
                      radius: 50.r,
                      backgroundImage: const AssetImage(
                        'assets/images/default_profile.png',
                      ),
                    ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.name,
                      style: GoogleFonts.poppins(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      trainer.trainerType.isNotEmpty
                          ? trainer.trainerType
                          : 'Fitness Professional',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          trainer.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '(${trainer.followers} followers)',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    if (trainer.tagline.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        trainer.tagline,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(Professional trainer) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            trainer.bio.isNotEmpty ? trainer.bio : 'No bio available',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(
            icon: Symbols.work_rounded,
            label: 'Experience',
            value:
                trainer.experience.isNotEmpty
                    ? '${trainer.experience} years'
                    : 'N/A',
          ),
          _buildDetailRow(
            icon: Symbols.person_rounded,
            label: 'Occupation',
            value:
                trainer.currentOccupation.isNotEmpty
                    ? trainer.currentOccupation
                    : 'N/A',
          ),
          _buildDetailRow(
            icon: Symbols.schedule_rounded,
            label: 'Availability',
            value:
                trainer.availableTimings.isNotEmpty
                    ? trainer.availableTimings
                    : 'N/A',
          ),
          _buildDetailRow(
            icon: Symbols.location_on_rounded,
            label: 'City',
            value: trainer.city.isNotEmpty ? trainer.city : 'N/A',
          ),
          _buildDetailRow(
            icon: Symbols.language_rounded,
            label: 'Languages',
            value:
                trainer.languages.isNotEmpty
                    ? trainer.languages.join(', ')
                    : 'N/A',
          ),
          _buildDetailRow(
            icon: Symbols.monetization_on_rounded,
            label: 'Chat Fee',
            value:
                trainer.feesChat > 0
                    ? '₹${trainer.feesChat.toStringAsFixed(2)}'
                    : 'N/A',
          ),
          _buildDetailRow(
            icon: Symbols.monetization_on_rounded,
            label: 'Call Fee',
            value:
                trainer.feesCall > 0
                    ? '₹${trainer.feesCall.toStringAsFixed(2)}'
                    : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '$label: $value',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Send a message...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Symbols.send_rounded,
                  color: AppTheme.primaryColor,
                  size: 20.sp,
                ),
                onPressed:
                    _isSendingMessage || _messageController.text.trim().isEmpty
                        ? null
                        : () => _sendMessage(_messageController.text.trim()),
              ),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startAudioCall,
                  icon: Icon(
                    Symbols.call_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Audio Call',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startVideoCall,
                  icon: Icon(
                    Symbols.videocam_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Video Call',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
